import dotenv from "dotenv";
import { config, higgsfield } from "@higgsfield/client/v2";

// Load environment variables from .env.local
dotenv.config({ path: ".env.local" });

async function main() {
  const credentials = process.env.HF_CREDENTIALS;

  if (!credentials || credentials.trim() === "" || credentials.includes("your-key-id:your-key-secret")) {
    console.error("\n❌ [BLOCKER] HF_CREDENTIALS is missing or has placeholder values in .env.local.");
    console.error("Please add your Higgsfield API key ID and Secret in 'key-id:key-secret' format to .env.local.");
    console.error("Example: HF_CREDENTIALS=hf_key_123456789:sec_abcdef123456789\n");
    process.exit(1);
  }

  // Configure client with credentials loaded server-side without exposing or printing them
  config({
    credentials: credentials.trim(),
  });

  const model = "bytedance/seedance-2.5/text-to-video";
  const input = {
    prompt: "A cinematic scene at sunset",
    duration: 5,
    resolution: "720p",
    aspect_ratio: "16:9",
  };

  console.log("==================================================");
  console.log("Higgsfield API - Seedance 2.5 Video Generation");
  console.log("==================================================");
  console.log(`Model:        ${model}`);
  console.log(`Prompt:       "${input.prompt}"`);
  console.log(`Duration:     ${input.duration} seconds`);
  console.log(`Resolution:   ${input.resolution}`);
  console.log(`Aspect Ratio: ${input.aspect_ratio}`);
  console.log("Submitting request and waiting for completion (withPolling: true)...");

  try {
    const result = await higgsfield.subscribe(model, {
      input,
      withPolling: true,
    });

    console.log(`\nRequest ID: ${result.request_id || "N/A"}`);
    console.log(`Final Status: ${result.status}`);

    if (result.status === "completed") {
      const videoUrl =
        result.video?.url ||
        (result as { videos?: Array<{ url: string }> }).videos?.[0]?.url ||
        (result as { output?: { url?: string } }).output?.url;

      if (videoUrl) {
        console.log("\n==================================================");
        console.log("✅ Generation completed successfully!");
        console.log(`Generated Video URL: ${videoUrl}`);
        console.log("==================================================\n");
      } else {
        console.error("\n❌ Request marked 'completed', but no video URL was returned in the response payload.");
        process.exit(1);
      }
    } else if (result.status === "failed") {
      console.error("\n❌ Generation FAILED: The request failed during processing.");
      process.exit(1);
    } else if (result.status === "nsfw" || (result.status as string) === "moderated") {
      console.error("\n❌ Generation MODERATED: The request triggered content safety / moderation filters.");
      process.exit(1);
    } else if ((result.status as string) === "canceled" || (result.status as string) === "cancelled") {
      console.error("\n❌ Generation CANCELED: The request was canceled.");
      process.exit(1);
    } else {
      console.error(`\n❌ Generation ended with unhandled status: ${result.status}`);
      process.exit(1);
    }
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`\n❌ Request Error: ${errorMessage}`);
    process.exit(1);
  }
}

main();
