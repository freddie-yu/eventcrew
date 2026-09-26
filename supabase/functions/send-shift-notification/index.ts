import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

type DispatchPayload = {
  userId: string;
  eventId?: string;
  title: string;
  body: string;
};

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const expectedSecret = Deno.env.get("NOTIFICATION_DISPATCH_SECRET");
  const suppliedSecret = request.headers.get("x-dispatch-secret");

  if (!expectedSecret || suppliedSecret !== expectedSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = (await request.json()) as DispatchPayload;
  if (!payload.userId || !payload.title || !payload.body) {
    return new Response("Missing notification fields", { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

  if (!supabaseUrl || !serviceRoleKey || !rawServiceAccount) {
    return new Response("Server configuration incomplete", { status: 500 });
  }

  const serviceAccount = JSON.parse(rawServiceAccount);
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: tokenRows, error: tokenError } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", payload.userId);

  if (tokenError) throw tokenError;

  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const authClient = await auth.getClient();
  const accessToken = await authClient.getAccessToken();

  if (!accessToken.token) {
    return new Response("Could not obtain FCM access token", { status: 500 });
  }

  const projectId = serviceAccount.project_id as string;
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  let sent = 0;
  for (const row of tokenRows ?? []) {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken.token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: row.token,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: {
            event_id: payload.eventId ?? "",
          },
        },
      }),
    });

    if (response.ok) sent += 1;
  }

  const { error: notificationError } = await supabase
    .from("notifications")
    .insert({
      user_id: payload.userId,
      event_id: payload.eventId ?? null,
      title: payload.title,
      body: payload.body,
    });

  if (notificationError) throw notificationError;

  return Response.json({ sent });
});
