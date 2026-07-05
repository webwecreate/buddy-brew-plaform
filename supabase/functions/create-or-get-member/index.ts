// Supabase Edge Function: create-or-get-member
// (deployed via GitHub Actions — verifying auto-deploy pipeline)
// Verifies a LINE LIFF ID token server-side, then creates or fetches the
// matching member row. The anon key never touches the members table directly —
// this function is the only door in, using the service role key.
//
// Deploy: supabase functions deploy create-or-get-member
// Required secrets: LIFF_CHANNEL_ID, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { idToken } = await req.json();
    if (!idToken) {
      return new Response(JSON.stringify({ error: "missing idToken" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const verifyRes = await fetch("https://api.line.me/oauth2/v2.1/verify", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        id_token: idToken,
        client_id: Deno.env.get("LIFF_CHANNEL_ID") ?? "",
      }),
    });

    if (!verifyRes.ok) {
      return new Response(JSON.stringify({ error: "invalid id token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const linePayload = await verifyRes.json();
    const lineUserId = linePayload.sub;
    const displayName = linePayload.name ?? "สมาชิก";
    const pictureUrl = linePayload.picture ?? null;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Single round trip: insert on first login, or update display_name/picture_url
    // on repeat logins (point/tier are untouched since they're not in this payload).
    const { data: member, error: upsertError } = await supabase
      .from("members")
      .upsert(
        { line_user_id: lineUserId, display_name: displayName, picture_url: pictureUrl },
        { onConflict: "line_user_id" },
      )
      .select("id, display_name, picture_url, tier, point, created_at")
      .single();

    if (upsertError) {
      console.error("upsert member failed:", upsertError.message);
      return new Response(JSON.stringify({ error: upsertError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const isNew = Date.now() - new Date(member.created_at).getTime() < 5000;

    return new Response(JSON.stringify({ member, isNew }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("unhandled error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
