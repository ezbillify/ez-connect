// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.46.0";
import { serve } from "https://deno.land/std@0.210.0/http/server.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const smtpFrom = Deno.env.get("SMTP_FROM") || "noreply@example.com";

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set");
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
  },
});

interface AdminContext {
  userId: string;
  userEmail: string;
  userRole: string;
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

async function validateAdmin(token: string): Promise<AdminContext> {
  const { data: { user }, error: userError } = await supabase.auth.getUser(token);
  
  if (userError || !user) {
    throw new Response(
      JSON.stringify({ error: "invalid_token", message: "Authentication failed" }),
      { status: 401 }
    );
  }

  // Fetch user profile to check role
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("role, email, full_name")
    .eq("id", user.id)
    .single();

  if (profileError || !profile) {
    throw new Response(
      JSON.stringify({ error: "profile_not_found", message: "User profile not found" }),
      { status: 403 }
    );
  }

  if (profile.role !== "admin") {
    throw new Response(
      JSON.stringify({ error: "insufficient_permissions", message: "Admin role required" }),
      { status: 403 }
    );
  }

  return {
    userId: user.id,
    userEmail: profile.email,
    userRole: profile.role,
  };
}

async function sendInvitationEmail(email: string, invitationCode: string, role: string) {
  // In production, this would use Supabase SMTP settings or a service like SendGrid/Postmark
  // For now, we'll use Supabase's built-in email functionality
  
  const inviteUrl = `${supabaseUrl}/auth/v1/verify?token=${invitationCode}&type=invite&redirect_to=${supabaseUrl}`;
  
  try {
    // Attempt to send email via Supabase Auth
    const { error } = await supabase.auth.admin.inviteUserByEmail(email, {
      data: {
        role: role,
        invitation_code: invitationCode,
      },
      redirectTo: inviteUrl,
    });

    if (error) {
      console.error("Email send error:", error);
      return { success: false, error: error.message };
    }

    return { success: true };
  } catch (err) {
    console.error("Failed to send invitation email:", err);
    return { success: false, error: (err as Error).message };
  }
}

async function sendPasswordResetEmail(email: string) {
  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${supabaseUrl}/auth/reset-password`,
    });

    if (error) {
      console.error("Password reset email error:", error);
      return { success: false, error: error.message };
    }

    return { success: true };
  } catch (err) {
    console.error("Failed to send password reset email:", err);
    return { success: false, error: (err as Error).message };
  }
}

async function handleCreateInvitation(body: any, context: AdminContext) {
  if (!body?.email) {
    return jsonResponse({ error: "missing_email" }, { status: 400 });
  }

  const email = body.email.toLowerCase().trim();
  const role = body.role || "agent";

  // Validate role
  if (!["agent", "admin"].includes(role)) {
    return jsonResponse({ error: "invalid_role", message: "Role must be 'agent' or 'admin'" }, { status: 400 });
  }

  try {
    // Call SQL function to create invitation
    const { data, error } = await supabase.rpc("create_user_invitation", {
      p_email: email,
      p_role: role,
      p_invited_by: context.userId,
    });

    if (error) {
      return jsonResponse({ error: "invitation_failed", details: error.message }, { status: 500 });
    }

    const invitation = data as any;

    // Send invitation email
    const emailResult = await sendInvitationEmail(
      invitation.email,
      invitation.invitation_code,
      invitation.role
    );

    return jsonResponse({
      success: true,
      invitation: {
        id: invitation.invitation_id,
        email: invitation.email,
        role: invitation.role,
        created_at: invitation.created_at,
      },
      email_sent: emailResult.success,
      email_error: emailResult.error || null,
    }, { status: 201 });
  } catch (err) {
    if (err instanceof Response) throw err;
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

async function handleResendInvitation(invitationId: string, context: AdminContext) {
  try {
    // Call SQL function to resend invitation
    const { data, error } = await supabase.rpc("resend_user_invitation", {
      p_invitation_id: invitationId,
      p_resent_by: context.userId,
    });

    if (error) {
      return jsonResponse({ error: "resend_failed", details: error.message }, { status: 500 });
    }

    const invitation = data as any;

    // Send invitation email
    const emailResult = await sendInvitationEmail(
      invitation.email,
      invitation.invitation_code,
      "agent" // Default role for resend
    );

    return jsonResponse({
      success: true,
      invitation: {
        id: invitation.invitation_id,
        email: invitation.email,
        resent_at: invitation.resent_at,
      },
      email_sent: emailResult.success,
      email_error: emailResult.error || null,
    });
  } catch (err) {
    if (err instanceof Response) throw err;
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

async function handleBulkUpdateRoles(body: any, context: AdminContext) {
  if (!body?.user_ids || !Array.isArray(body.user_ids)) {
    return jsonResponse({ error: "missing_user_ids", message: "user_ids must be an array" }, { status: 400 });
  }

  if (!body?.new_role) {
    return jsonResponse({ error: "missing_new_role" }, { status: 400 });
  }

  const role = body.new_role;
  if (!["agent", "admin"].includes(role)) {
    return jsonResponse({ error: "invalid_role", message: "Role must be 'agent' or 'admin'" }, { status: 400 });
  }

  try {
    // Call SQL function to bulk update roles
    const { data, error } = await supabase.rpc("bulk_update_user_roles", {
      p_user_ids: body.user_ids,
      p_new_role: role,
      p_updated_by: context.userId,
    });

    if (error) {
      return jsonResponse({ error: "bulk_update_failed", details: error.message }, { status: 500 });
    }

    return jsonResponse({
      success: true,
      result: data,
    });
  } catch (err) {
    if (err instanceof Response) throw err;
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

async function handleToggleUserStatus(userId: string, body: any, context: AdminContext) {
  if (typeof body?.is_active !== "boolean") {
    return jsonResponse({ error: "missing_is_active", message: "is_active must be a boolean" }, { status: 400 });
  }

  try {
    // Call SQL function to toggle user status
    const { data, error } = await supabase.rpc("toggle_user_status", {
      p_user_id: userId,
      p_is_active: body.is_active,
      p_toggled_by: context.userId,
    });

    if (error) {
      return jsonResponse({ error: "toggle_failed", details: error.message }, { status: 500 });
    }

    return jsonResponse({
      success: true,
      result: data,
    });
  } catch (err) {
    if (err instanceof Response) throw err;
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

async function handleResetPassword(userId: string, body: any, context: AdminContext) {
  if (!body?.new_password) {
    return jsonResponse({ error: "missing_new_password" }, { status: 400 });
  }

  if (body.new_password.length < 6) {
    return jsonResponse({ error: "password_too_short", message: "Password must be at least 6 characters" }, { status: 400 });
  }

  try {
    // Call SQL function to reset password
    const { data, error } = await supabase.rpc("reset_user_password", {
      p_user_id: userId,
      p_new_password: body.new_password,
      p_reset_by: context.userId,
    });

    if (error) {
      return jsonResponse({ error: "reset_failed", details: error.message }, { status: 500 });
    }

    const result = data as any;

    // Send password reset notification email
    const emailResult = await sendPasswordResetEmail(result.email);

    return jsonResponse({
      success: true,
      result: {
        user_id: result.user_id,
        email: result.email,
        reset_at: result.reset_at,
      },
      email_sent: emailResult.success,
      email_error: emailResult.error || null,
    });
  } catch (err) {
    if (err instanceof Response) throw err;
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

async function handleGetActivityLog(query: URLSearchParams) {
  const limit = parseInt(query.get("limit") || "100");
  const offset = parseInt(query.get("offset") || "0");

  try {
    const { data, error } = await supabase.rpc("get_user_activity_log", {
      p_limit: limit,
      p_offset: offset,
    });

    if (error) {
      return jsonResponse({ error: "fetch_failed", details: error.message }, { status: 500 });
    }

    return jsonResponse({
      success: true,
      logs: data,
      pagination: {
        limit,
        offset,
      },
    });
  } catch (err) {
    return jsonResponse({
      error: "internal_error",
      details: (err as Error).message,
    }, { status: 500 });
  }
}

serve(async (req: Request) => {
  const url = new URL(req.url);
  const pathname = url.pathname.replace(/^\/+/, "/");
  let context: AdminContext | null = null;
  let requestBody: any = null;
  let response: Response;

  try {
    // Parse and validate auth token
    const token = parseAuthToken(req);
    if (!token) {
      response = jsonResponse({ error: "missing_token", message: "Authorization header required" }, { status: 401 });
      return response;
    }

    context = await validateAdmin(token);

    // Parse request body for non-GET requests
    if (req.method !== "GET" && req.method !== "HEAD") {
      try {
        requestBody = await req.json();
      } catch (_err) {
        return jsonResponse({ error: "invalid_json" }, { status: 400 });
      }
    }

    // Route handling
    if (pathname === "/" && req.method === "GET") {
      response = jsonResponse({
        status: "ok",
        service: "user-admin",
        version: "1.0.0",
        endpoints: [
          "POST /invitations - Create user invitation",
          "POST /invitations/:id/resend - Resend invitation",
          "POST /users/roles/bulk - Bulk update user roles",
          "PATCH /users/:id/status - Toggle user status",
          "PATCH /users/:id/password - Reset user password",
          "GET /activity-log - Get user activity log",
        ],
      });
      return response;
    }

    // Create invitation
    if (pathname === "/invitations" && req.method === "POST") {
      response = await handleCreateInvitation(requestBody, context);
      return response;
    }

    // Resend invitation
    const resendMatch = pathname.match(/^\/invitations\/([a-f0-9-]+)\/resend$/);
    if (resendMatch && req.method === "POST") {
      response = await handleResendInvitation(resendMatch[1], context);
      return response;
    }

    // Bulk update roles
    if (pathname === "/users/roles/bulk" && req.method === "POST") {
      response = await handleBulkUpdateRoles(requestBody, context);
      return response;
    }

    // Toggle user status
    const statusMatch = pathname.match(/^\/users\/([a-f0-9-]+)\/status$/);
    if (statusMatch && req.method === "PATCH") {
      response = await handleToggleUserStatus(statusMatch[1], requestBody, context);
      return response;
    }

    // Reset password
    const passwordMatch = pathname.match(/^\/users\/([a-f0-9-]+)\/password$/);
    if (passwordMatch && req.method === "PATCH") {
      response = await handleResetPassword(passwordMatch[1], requestBody, context);
      return response;
    }

    // Get activity log
    if (pathname === "/activity-log" && req.method === "GET") {
      response = await handleGetActivityLog(url.searchParams);
      return response;
    }

    response = jsonResponse({ error: "not_found", message: "Endpoint not found" }, { status: 404 });
    return response;
  } catch (err) {
    if (err instanceof Response) {
      return err;
    }

    console.error("Unhandled error", err);
    response = jsonResponse({
      error: "internal_error",
      message: (err as Error).message,
    }, { status: 500 });
    return response;
  }
});
