import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
};

export default {
  async fetch(req: Request) {
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: corsHeaders,
      });
    }

    try {
      const authHeader =
          req.headers.get("Authorization");

      if (!authHeader) {
        return new Response(
          JSON.stringify({
            error: "Missing auth header",
          }),
          {
            status: 401,
            headers: corsHeaders,
          },
        );
      }

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        {
          global: {
            headers: {
              Authorization: authHeader,
            },
          },
        },
      );

      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser();

      if (userError || !user) {
        return new Response(
          JSON.stringify({
            error: "User not found",
          }),
          {
            status: 401,
            headers: corsHeaders,
          },
        );
      }

      const { data: logs, error: logsError } =
          await supabase
              .from("study_logs")
              .select("*")
              .eq("user_id", user.id);

      if (logsError) throw logsError;

      let totalHours = 0;

      for (const log of logs) {
        totalHours += Number(log.hours);
      }

      const today = new Date()
          .toISOString()
          .split("T")[0];

      let todayHours = 0;

      for (const log of logs) {
        const logDate =
            String(log.logged_date).split("T")[0];

        if (logDate === today) {
          todayHours += Number(log.hours);
        }
      }

      const studyDays = logs.length;

      const resendKey =
          Deno.env.get("RESEND_API_KEY");

      const emailHtml = `
      <div style="font-family:Arial;padding:20px">
        <h2>📚 Study Heatmap Daily Report</h2>

        <p><strong>Today's Study:</strong> ${todayHours.toFixed(1)}h</p>

        <p><strong>Total Hours:</strong> ${totalHours.toFixed(1)}h</p>

        <p><strong>Study Days:</strong> ${studyDays}</p>

        <hr>

        <p>Keep building consistency.</p>
      </div>
      `;

      const resendResponse =
          await fetch(
            "https://api.resend.com/emails",
            {
              method: "POST",
              headers: {
                Authorization:
                    `Bearer ${resendKey}`,
                "Content-Type":
                    "application/json",
              },
              body: JSON.stringify({
                from:
                    "onboarding@resend.dev",
                to: [
                  "dsai3354@gmail.com"
                ],
                subject:
                    "📚 Your Daily Study Report",
                html: emailHtml,
              }),
            },
          );

      const data =
          await resendResponse.json();

      return new Response(
        JSON.stringify(data),
        {
          headers: {
            ...corsHeaders,
            "Content-Type":
                "application/json",
          },
        },
      );
    } catch (e) {
      return new Response(
        JSON.stringify({
          error: e.toString(),
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type":
                "application/json",
          },
        },
      );
    }
  },
};