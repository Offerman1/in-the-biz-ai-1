// Test script to see what Gemini extracts from the checkout images
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as fs from 'fs';
import * as path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function testCheckoutScan() {
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
  
  // Read the HEIC files
  const image1Path = path.join(process.cwd(), 'assets', 'IMG_20260106_135022.heic');
  const image2Path = path.join(process.cwd(), 'assets', 'IMG_20260106_135024.heic');
  
  console.log('Reading images...');
  console.log('Image 1:', image1Path, 'exists:', fs.existsSync(image1Path));
  console.log('Image 2:', image2Path, 'exists:', fs.existsSync(image2Path));
  
  const image1Data = fs.readFileSync(image1Path);
  const image2Data = fs.readFileSync(image2Path);
  
  console.log('Image 1 size:', image1Data.length, 'bytes');
  console.log('Image 2 size:', image2Data.length, 'bytes');
  
  // Prepare images for Gemini
  const imageParts = [
    {
      inlineData: {
        data: image1Data.toString('base64'),
        mimeType: 'image/heic',
      },
    },
    {
      inlineData: {
        data: image2Data.toString('base64'),
        mimeType: 'image/heic',
      },
    },
  ];

  const prompt = `You are an expert at analyzing restaurant Point of Sale (POS) system checkout receipts.

TASK: Extract ALL financial data from this 2-page server checkout receipt.

Tell me EVERY piece of text you can see on these images. I want to know:
1. What labels/headers do you see?
2. What numbers are next to each label?
3. Is there anything about tips, sales, comps, sections, etc?

Just list everything you can read from the images.`;

  console.log('\nSending to Gemini...\n');
  
  try {
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = result.response;
    const text = response.text();
    
    console.log('=== GEMINI RESPONSE ===');
    console.log(text);
    console.log('=== END RESPONSE ===');
  } catch (error) {
    console.error('Error:', error.message);
    
    // Try with image/jpeg mime type instead
    console.log('\nTrying with image/jpeg mime type...\n');
    
    const imagePartsJpeg = [
      {
        inlineData: {
          data: image1Data.toString('base64'),
          mimeType: 'image/jpeg',
        },
      },
      {
        inlineData: {
          data: image2Data.toString('base64'),
          mimeType: 'image/jpeg',
        },
      },
    ];
    
    try {
      const result = await model.generateContent([prompt, ...imagePartsJpeg]);
      const response = result.response;
      const text = response.text();
      
      console.log('=== GEMINI RESPONSE (jpeg mime) ===');
      console.log(text);
      console.log('=== END RESPONSE ===');
    } catch (error2) {
      console.error('Error with jpeg:', error2.message);
    }
  }
}

testCheckoutScan();
