// Job Detector - Auto-detects which job to use or generates clarifying questions
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class JobDetector {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async detectJob(message: string, providedJobId?: string): Promise<{
    jobId: string | null;
    needsClarification: boolean;
    clarificationMessage?: string;
    availableJobs?: any[];
  }> {
    // If job ID explicitly provided, use it
    if (providedJobId) {
      return {
        jobId: providedJobId,
        needsClarification: false,
      };
    }

    // Get user's active jobs
    const { data: jobs, error } = await this.supabase
      .from("jobs")
      .select("*")
      .eq("user_id", this.userId)
      .eq("is_active", true)
      .is("deleted_at", null);

    if (error) throw error;

    // No jobs - suggest creating one
    if (jobs.length === 0) {
      return {
        jobId: null,
        needsClarification: true,
        clarificationMessage: "You don't have any jobs set up yet. Would you like to create one?",
        availableJobs: [],
      };
    }

    // One job - auto-select
    if (jobs.length === 1) {
      return {
        jobId: jobs[0].id,
        needsClarification: false,
      };
    }

    // Multiple jobs - check if job mentioned in message
    const lowerMessage = message.toLowerCase();

    for (const job of jobs) {
      const jobName = job.name.toLowerCase();

      // Check for exact or partial name match
      if (lowerMessage.includes(jobName)) {
        return {
          jobId: job.id,
          needsClarification: false,
        };
      }

      // Check for role keywords (e.g., user says "bartending" but job is "Bartender")
      const roleKeywords = this.extractRoleKeywords(jobName);
      for (const keyword of roleKeywords) {
        if (lowerMessage.includes(keyword)) {
          return {
            jobId: job.id,
            needsClarification: false,
          };
        }
      }
    }

    // Check for default job
    const defaultJob = jobs.find((j) => j.is_default);
    if (defaultJob) {
      return {
        jobId: defaultJob.id,
        needsClarification: false,
      };
    }

    // No match found - ask user
    const jobOptions = jobs
      .map((job, index) => `${index + 1}. ${job.name}${job.is_default ? " (default)" : ""}`)
      .join("\n");

    return {
      jobId: null,
      needsClarification: true,
      clarificationMessage: `Which job was this for?\n\n${jobOptions}\n\nPlease specify the job name or number.`,
      availableJobs: jobs,
    };
  }

  private extractRoleKeywords(jobName: string): string[] {
    const lowerName = jobName.toLowerCase();
    const keywords: string[] = [];

    // Extract root words
    if (lowerName.includes("bartend")) keywords.push("bartend", "bartending", "bar");
    if (lowerName.includes("server") || lowerName.includes("wait")) keywords.push("server", "serving", "waitress", "waiter");
    if (lowerName.includes("barber")) keywords.push("barber", "barbering", "haircut");
    if (lowerName.includes("hair")) keywords.push("hair", "hairstylist", "stylist");
    if (lowerName.includes("nail")) keywords.push("nail", "nails", "manicure");
    if (lowerName.includes("event")) keywords.push("event", "events", "catering");

    return keywords;
  }

  async getJobById(jobId: string): Promise<any | null> {
    const { data, error } = await this.supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .single();

    if (error) return null;
    return data;
  }
}
