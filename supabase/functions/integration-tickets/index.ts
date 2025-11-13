// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.46.0";
import { serve } from "https://deno.land/std@0.210.0/http/server.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set");
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
  },
});

interface IntegrationContext {
  tokenId: string;
  userId: string;
  tokenName?: string;
}

interface RequestMeta {
  ip?: string;
  userAgent?: string;
  endpoint: string;
  method: string;
}

const jsonResponse = (data: any, init: ResponseInit = {}) =>
  new Response(JSON.stringify(data, null, 2), {
    headers: {
      "content-type": "application/json",
      "x-powered-by": "supabase-edge-functions",
      ...init.headers,
    },
    status: init.status ?? 200,
  });

const parseAuthToken = (req: Request): string | null => {
  const authHeader = req.headers.get("authorization") ?? req.headers.get("Authorization");
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) return null;
  return token.trim();
};

async function validateToken(token: string, meta: RequestMeta): Promise<IntegrationContext> {
  const { data, error } = await supabase.rpc("validate_integration_token", {
    p_token: token,
    p_endpoint: meta.endpoint,
    p_method: meta.method,
    p_ip_address: meta.ip ?? null,
    p_user_agent: meta.userAgent ?? null,
  });

  if (error) {
    throw new Response(JSON.stringify({ error: "validation_failed", details: error.message }), { status: 500 });
  }

  if (!data?.length) {
    throw new Response(JSON.stringify({ error: "invalid_token" }), { status: 401 });
  }

  const validation = data[0];
  if (!validation.valid) {
    const status = validation.rate_limit_exceeded ? 429 : 401;
    throw new Response(JSON.stringify({
      error: validation.rate_limit_exceeded ? "rate_limit_exceeded" : "invalid_token",
      message: validation.error_message ?? "",
    }), { status });
  }

  return {
    tokenId: validation.token_id,
    userId: validation.user_id,
  } as IntegrationContext;
}

async function logUsage(
  context: IntegrationContext,
  meta: RequestMeta,
  statusCode: number,
  start: number,
  payload?: any,
  errorMessage?: string,
) {
  try {
    await supabase.rpc("log_integration_token_usage", {
      p_token_id: context.tokenId,
      p_endpoint: meta.endpoint,
      p_method: meta.method,
      p_status_code: statusCode,
      p_response_time_ms: Math.max(Date.now() - start, 0),
      p_ip_address: meta.ip ?? null,
      p_user_agent: meta.userAgent ?? null,
      p_request_payload: payload ?? null,
      p_error_message: errorMessage ?? null,
    });
  } catch (loggingError) {
    console.error("Failed to log integration usage", loggingError);
  }
}

const getRequestMeta = (req: Request, endpoint: string): RequestMeta => ({
  ip: req.headers.get("x-forwarded-for") ?? req.headers.get("cf-connecting-ip") ?? undefined,
  userAgent: req.headers.get("user-agent") ?? undefined,
  endpoint,
  method: req.method,
});

async function handleCreateTicket(body: any, context: IntegrationContext) {
  if (!body?.title) {
    return jsonResponse({ error: "missing_title" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("create_ticket_via_integration", {
    p_token_id: context.tokenId,
    p_user_id: context.userId,
    p_title: body.title,
    p_description: body.description ?? null,
    p_priority: body.priority ?? "medium",
    p_category: body.category ?? null,
    p_metadata: body.metadata ?? null,
  });

  if (error) {
    return jsonResponse({ error: "create_failed", details: error.message }, { status: 500 });
  }

  const ticketId = data as string;

  const { data: ticket, error: fetchError } = await supabase
    .from("tickets")
    .select("id, title, description, status, priority, category, metadata, created_at")
    .eq("id", ticketId)
    .single();

  if (fetchError) {
    return jsonResponse({ id: ticketId }, { status: 201 });
  }

  return jsonResponse({ ticket }, { status: 201 });
}

async function handleGetTicket(ticketId: string, context: IntegrationContext) {
  const { data, error } = await supabase
    .from("tickets")
    .select("id, title, description, status, priority, category, metadata, created_at, updated_at")
    .eq("id", ticketId)
    .eq("integration_source", context.tokenId)
    .maybeSingle();

  if (error) {
    return jsonResponse({ error: "fetch_failed", details: error.message }, { status: 500 });
  }

  if (!data) {
    return jsonResponse({ error: "not_found" }, { status: 404 });
  }

  return jsonResponse({ ticket: data });
}

async function handleAddComment(ticketId: string, body: any, context: IntegrationContext) {
  if (!body?.content) {
    return jsonResponse({ error: "missing_content" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("add_ticket_comment_via_integration", {
    p_token_id: context.tokenId,
    p_user_id: context.userId,
    p_ticket_id: ticketId,
    p_content: body.content,
    p_is_internal: body.is_internal ?? false,
  });

  if (error) {
    return jsonResponse({ error: "comment_failed", details: error.message }, { status: 500 });
  }

  const commentId = data as string;
  return jsonResponse({ comment_id: commentId }, { status: 201 });
}

async function handleUpdateStatus(ticketId: string, body: any, context: IntegrationContext) {
  if (!body?.status) {
    return jsonResponse({ error: "missing_status" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("update_ticket_status_via_integration", {
    p_token_id: context.tokenId,
    p_user_id: context.userId,
    p_ticket_id: ticketId,
    p_status: body.status,
  });

  if (error) {
    return jsonResponse({ error: "status_failed", details: error.message }, { status: 500 });
  }

  if (!data) {
    return jsonResponse({ success: false }, { status: 400 });
  }

  const { data: ticket, error: fetchError } = await supabase
    .from("tickets")
    .select("id, status, updated_at")
    .eq("id", ticketId)
    .maybeSingle();

  if (fetchError || !ticket) {
    return jsonResponse({ success: true });
  }

  return jsonResponse({ success: true, ticket });
}

serve(async (req: Request) => {
  const start = Date.now();
  const url = new URL(req.url);
  const pathname = url.pathname.replace(/^\/+/, "/");
  const meta = getRequestMeta(req, pathname);
  let context: IntegrationContext | null = null;
  let requestBody: any = null;
  let response: Response;

  const logResponse = async (status: number, errorMessage?: string) => {
    if (!context) return;
    await logUsage(context, meta, status, start, requestBody, errorMessage);
  };

  try {
    const token = parseAuthToken(req);
    if (!token) {
      response = jsonResponse({ error: "missing_token" }, { status: 401 });
      return response;
    }

    context = await validateToken(token, meta);

    if (req.method !== "GET" && req.method !== "HEAD") {
      try {
        requestBody = await req.json();
      } catch (_err) {
        requestBody = null;
      }
    }

    // Route handling
    if (pathname === "/" && req.method === "GET") {
      response = jsonResponse({
        status: "ok",
        endpoints: [
          "POST /tickets",
          "GET /tickets/:id",
          "POST /tickets/:id/comments",
          "PATCH /tickets/:id/status",
        ],
      });
      await logResponse(response.status);
      return response;
    }

    if (pathname === "/tickets" && req.method === "POST") {
      response = await handleCreateTicket(requestBody, context);
      await logResponse(response.status);
      return response;
    }

    const ticketMatch = pathname.match(/^\/tickets\/(.+)$/);
    if (ticketMatch) {
      const remainder = ticketMatch[1];
      const [ticketId, subresource, maybeAction] = remainder.split("/");

      if (!ticketId) {
        response = jsonResponse({ error: "missing_ticket_id" }, { status: 400 });
        await logResponse(response.status);
        return response;
      }

      if (!subresource && req.method === "GET") {
        response = await handleGetTicket(ticketId, context);
        await logResponse(response.status);
        return response;
      }

      if (subresource === "comments" && req.method === "POST") {
        response = await handleAddComment(ticketId, requestBody, context);
        await logResponse(response.status);
        return response;
      }

      if (subresource === "status" && req.method === "PATCH") {
        response = await handleUpdateStatus(ticketId, requestBody, context);
        await logResponse(response.status);
        return response;
      }

      if (subresource && maybeAction) {
        response = jsonResponse({ error: "unsupported_route" }, { status: 404 });
        await logResponse(response.status);
        return response;
      }
    }

    response = jsonResponse({ error: "not_found" }, { status: 404 });
    await logResponse(response.status);
    return response;
  } catch (err) {
    if (err instanceof Response) {
      await logResponse(err.status);
      return err;
    }

    console.error("Unhandled error", err);
    response = jsonResponse({ error: "internal_error" }, { status: 500 });
    await logResponse(500, (err as Error).message);
    return response;
  }
});
