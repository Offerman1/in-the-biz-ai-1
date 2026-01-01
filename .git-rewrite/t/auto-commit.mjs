// Auto-commit watcher - runs alongside dev server
import { execSync } from 'child_process';
import { existsSync, unlinkSync, statSync } from 'fs';
import { join } from 'path';

console.log('🔄 Auto-commit watcher started (every 30 seconds)');

// Check for and remove stale lock files
function clearStaleLock() {
  const lockPath = join(process.cwd(), '.git', 'index.lock');
  
  if (existsSync(lockPath)) {
    try {
      const stats = statSync(lockPath);
      const ageInSeconds = (Date.now() - stats.mtimeMs) / 1000;
      
      // If lock file is older than 60 seconds, it's probably stale
      if (ageInSeconds > 60) {
        unlinkSync(lockPath);
        console.log(`🔓 Removed stale lock file (was ${Math.round(ageInSeconds)}s old)`);
      } else {
        console.log(`⏳ Lock file exists but is recent (${Math.round(ageInSeconds)}s old), waiting...`);
        return false; // Don't proceed, lock is fresh
      }
    } catch (e) {
      console.error('⚠️ Could not check/remove lock file:', e.message);
      return false;
    }
  }
  return true;
}

setInterval(() => {
  try {
    // Clear stale locks before attempting git operations
    if (!clearStaleLock()) {
      return; // Skip this cycle if lock is fresh
    }
    
    execSync('git add -A', { stdio: 'pipe' });
    const status = execSync('git status --porcelain', { encoding: 'utf-8' });
    
    if (status.trim()) {
      // Use safe timestamp format without spaces or colons
      const timestamp = new Date().toISOString().slice(0, 19).replace('T', '_').replace(/:/g, '-');
      execSync(`git commit -m "auto-save ${timestamp}"`, { stdio: 'pipe' });
      console.log(`✅ [${timestamp}] Committed changes`);
    }
  } catch (e) {
    // Log errors so we can see what's wrong
    if (e.message && !e.message.includes('nothing to commit')) {
      console.error('❌ Auto-commit error:', e.message);
    }
  }
}, 30000);
