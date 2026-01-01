import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();
puppeteer.use(StealthPlugin());

// Initialize Gemini Vision
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const visionModel = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });

// CONFIGURATION
const BASE_URL = 'http://localhost:8082'; // Flutter Web Port

const errors = [];
const visionReports = [];

console.log('🧪 PUPPETEER + AI VISION TEST\n');
console.log('👁️ AI Vision: ENABLED (Gemini 3 Flash)\n');

// ============================================================
// AI VISION HELPER FUNCTIONS
// ============================================================

async function askVision(screenshotBuffer, question) {
  try {
    const base64Image = screenshotBuffer.toString('base64');
    const result = await visionModel.generateContent([
      question,
      { inlineData: { data: base64Image, mimeType: "image/png" } }
    ]);
    return result.response.text();
  } catch (error) {
    console.log(`❌ Vision Error: ${error.message}`);
    return `ERROR: ${error.message}`;
  }
}

async function visionCheck(page, question) {
  const screenshot = await page.screenshot();
  const prompt = `Look at this web application screenshot. ${question}
Answer in this exact format:
ANSWER: YES or NO
DETAILS: [Brief explanation of what you see]`;

  const response = await askVision(screenshot, prompt);
  const isYes = response.toUpperCase().includes('ANSWER: YES');
  
  visionReports.push({ question, answer: isYes ? 'YES' : 'NO', details: response });
  return { answer: isYes, details: response };
}

async function describeUI(page) {
  const screenshot = await page.screenshot();
  return await askVision(screenshot, `Describe this web application UI in 2-3 sentences.`);
}

async function checkForVisualErrors(page) {
  const screenshot = await page.screenshot();
  const prompt = `Analyze this screenshot for errors (red text, broken layouts).
Return JSON: { "hasErrors": true/false, "errors": [], "overallHealth": "GOOD/WARNING/CRITICAL" }`;

  const response = await askVision(screenshot, prompt);
  try {
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) return JSON.parse(jsonMatch[0]);
  } catch (e) {}
  return { hasErrors: false, errors: [], overallHealth: 'UNKNOWN' };
}

// ============================================================
// MAIN TEST EXECUTION
// ============================================================

(async () => {
  const browser = await puppeteer.launch({
    headless: false,
    defaultViewport: null,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--start-maximized']
  });

  const page = await browser.newPage();

  try {
    // ========== TEST START ==========
    console.log('📍 Step 1: Home Page');
    await page.goto(`${BASE_URL}`, { waitUntil: 'networkidle0' });
    
    // AI Vision Description
    const description = await describeUI(page);
    console.log(`👁️ AI sees: ${description}`);
    
    // AI Health Check
    const health = await checkForVisualErrors(page);
    console.log(`👁️ Page Health: ${health.overallHealth}`);
    if (health.hasErrors) console.log(`⚠️ Errors: ${health.errors.join(', ')}`);

    // ========== CUSTOM TEST LOGIC HERE ==========
    console.log('\n📍 Step 2: Click Camera Button');
    // Find the floating action button with the camera icon
    // Note: Flutter web accessibility labels can be tricky. 
    // We'll look for the button that likely has the camera icon.
    // In the code: FloatingActionButton.large(child: Icon(Icons.camera_alt))
    
    // Let's try to find it by aria-label if Flutter adds one, or just click the FAB
    // Usually FABs are at the bottom right.
    
    // Wait for the FAB to be visible
    await page.waitForSelector('flt-semantics[aria-label="Camera"]', { timeout: 5000 }).catch(() => console.log("Could not find by aria-label 'Camera'"));
    
    // If we can't find it by label, let's try to find the button element
    // This is a bit hacky for Flutter Web, but we'll try to click the FAB.
    // We can use the AI to find the coordinates of the camera button!
    
    const screenshot = await page.screenshot();
    const buttonLocation = await askVision(screenshot, `
      Where is the large circular camera button located? 
      Return JSON: { "x": number, "y": number } 
      (Approximate center coordinates)
    `);
    
    console.log(`👁️ AI found button at: ${buttonLocation}`);
    
    try {
        const jsonMatch = buttonLocation.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            const coords = JSON.parse(jsonMatch[0]);
            await page.mouse.click(coords.x, coords.y);
            console.log('🖱️ Clicked at AI-detected coordinates');
        } else {
             // Fallback: Click bottom right corner where FAB usually is
             const viewport = page.viewport();
             if (viewport) {
                 await page.mouse.click(viewport.width - 50, viewport.height - 50);
                 console.log('🖱️ Clicked bottom right corner (Fallback)');
             } else {
                 // If viewport is null (maximized), assume standard 1920x1080 or similar
                 await page.mouse.click(1000, 600); // Approximate for default window
             }
        }
    } catch (e) {
        console.log('Error clicking button: ' + e.message);
    }

    await new Promise(resolve => setTimeout(resolve, 2000));
    
    console.log('👁️ AI sees (Camera Screen): ' + await describeUI(page));
    
    console.log('\n📍 Step 3: Verify Camera Options');
    const cameraCheck = await visionCheck(page, "Do you see options to 'Take Photo' and 'Choose from Gallery'?");
    console.log(`👁️ Camera Options Visible: ${cameraCheck.answer}`);
    
    const finalHealth = await checkForVisualErrors(page);
    console.log(`👁️ Final Page Health: ${finalHealth.overallHealth}`);

    // Add your specific test steps here...

  } catch (e) {
    console.error('❌ TEST FAILED:', e);
  } finally {
    // await browser.close(); // Keep open for debugging if needed
    console.log('✅ Test Complete');
  }
})();
