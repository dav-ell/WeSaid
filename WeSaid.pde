/*
 * ,--.   ,--.        ,---.          ,--.   ,--. 
 * |  |   |  | ,---. '   .-'  ,--,--.`--' ,-|  | 
 * |  |.'.|  || .-. :`.  `-. ' ,-.  |,--.' .-. | 
 * |   ,'.   |\   --..-'    |\ '-'  ||  |\ `-' | 
 * '--'   '--' `----'`-----'  `--`--'`--' `---' 
 *  Copyright (c) David Elliott and Yuxin Tseng
 */

import java.util.List;

// Global vars
List<PImage> images = new ArrayList<PImage>();
PImage screenImage;
int HEADER_HEIGHT;
PrintWriter writer;
int currentDisplayY;

// Phone constants
final double IOS_HEADER_RATIO = 0.100;
final double AND_HEADER_RATIO = 0.135;

// Adjustable parameters per image
final boolean IS_IOS                           = false;
final int     ALLOWABLE_PIXEL_COLOR_DIFFERENCE = 5;
final double  MINIMUM_OVERLAP_PERCENTAGE       = 12.0;

void setup() {
 size(1080, 3500);
 //fullScreen();
 background(0);
 noStroke();
 fill(0);
 
 //for (int i=1; i<=6; i++) {
 //  images.add(loadImage("screens/and-i" + i + ".png"));
 //}
 //for (int i=1; i<=5; i++) {
 // images.add(loadImage("screens/ios-i" + i + ".PNG"));
 //}
 //for (int i=1; i<=3; i++) {
 // images.add(loadImage("screens/ell" + i + ".png"));
 //}
 for (int i=1; i<=5; i++) {
  images.add(loadImage("screens/and-groupme-" + i + ".png"));
 }
 
 HEADER_HEIGHT = (int) (((double) images.get(0).height) * (IS_IOS ? IOS_HEADER_RATIO : AND_HEADER_RATIO));
 println((double) images.get(0).height);
 println(HEADER_HEIGHT);
 PImage img1 = null, img2;
 for (int i=0; i<images.size() - 1; i++) {
   if (img1 == null) {
     img1 = images.get(i);
     img1.loadPixels();
   }
   img2 = images.get(i+1);  
   img2.loadPixels();
   int idealOverlapWindowHeight = calculateOverlap(img1, img2, i);
   PImage newImage = createNewImage(img1, img2, idealOverlapWindowHeight);
   img1 = newImage;
 }
 
 screenImage = img1;
 image(img1, (displayWidth - img1.width) / 2, currentDisplayY, img1.width, img1.height);
 img1.save("stitch.png");
 println("Display Height: " + displayHeight);
 println("Image Height: " + img1.height);
}

void draw() {
  
}

void mouseDragged() {
  int yDiff = mouseY - pmouseY;
  println(currentDisplayY);
  currentDisplayY += yDiff;
  if (currentDisplayY > 0) {
   currentDisplayY = 0;
  }
  if (currentDisplayY < -(screenImage.height - displayHeight)) {
   currentDisplayY = -(screenImage.height - displayHeight); 
  }
  background(255);
  image(screenImage, (displayWidth - screenImage.width) / 2, currentDisplayY, screenImage.width, screenImage.height);
}

int calculateOverlap(PImage img1, PImage img2, int iter) {
 writer = createWriter("debug/PercentEquality" + iter + ".csv");
 // Compare top window of img2 with bottom window of img1
 int idealOverlapWindowHeight = 0;
 double maxPercentEquality = 0;
 int leftMax = img1.height;
 int rightMax = img2.height - HEADER_HEIGHT;
 for (int i=1; i < leftMax && i < rightMax; i++) {  
   // Caculate similarity
   double percentEquality = percentageEquality(img1, img2, i);
   if (percentEquality > maxPercentEquality) {
     maxPercentEquality = percentEquality;
     idealOverlapWindowHeight = i;
   }
   //println("Window size of " + i + " is: " + percentEquality);
   writer.println(i + "," + percentEquality);
   writer.flush();
 }
 
 // Threshold of non-overlap
 if(maxPercentEquality < MINIMUM_OVERLAP_PERCENTAGE) {
   idealOverlapWindowHeight = HEADER_HEIGHT;
 }
 
 println("Proposed window height for optimal overlap: " + idealOverlapWindowHeight);
 println("Percent equality is now : "+ maxPercentEquality);
 writer.flush();
 writer.close();
 
 return idealOverlapWindowHeight;
}

PImage createNewImage(PImage img1, PImage img2, int idealOverlapWindowHeight) {
 // THE MOST AMAZING ALGORITHM IN THE WORLD:
 //   1. Insert pixels from the left image in range [0, left.height - windowSize]
 //   2. Find header size
 //   3. Insert pixels from the right image in range [headerSize, right.height]

 PImage newOutput;
 int totalImageHeight = (img1.height - idealOverlapWindowHeight) + (img2.height - HEADER_HEIGHT);
 newOutput = createImage(img1.width, totalImageHeight, RGB);
 newOutput.loadPixels();
 
 int img1CutOff = img1.height - idealOverlapWindowHeight;
 for (int i = 0; i<img1CutOff; i++){
   for(int j = 0; j<img1.width; j++){
      newOutput.pixels[i * img1.width + j]= img1.pixels[i * img1.width + j];
   }
 }

 // Second part of the image
 for (int i = HEADER_HEIGHT; i<img2.height; i++){
    for(int j = 0; j<img2.width; j++){
      newOutput.pixels[(img1CutOff - HEADER_HEIGHT + i) * img1.width + j]= img2.pixels[i * img2.width + j];
    }
 }
 
 newOutput.updatePixels(); 
 return newOutput;
}

double percentageEquality(PImage left, PImage right, int totalWindowSize) {
  int totalEqual = 0;
  // Gradually perform comparisons on the bottom of the left image and the top of the right image
  // with increasing window size.
  for (int i=0; i < totalWindowSize; i++) {
    int leftRowNumber = left.height - totalWindowSize + i;
    int rightRowNumber = i + HEADER_HEIGHT;
    // We have the row number for the left (offset from bottom) and right (from top).
    // Now compare pixels row by row.
    for (int x=0; x < left.width; x++) {
      if (isCloseEnough(left.pixels[left.width * leftRowNumber + x], 
                        right.pixels[right.width * rightRowNumber + x])) {
        totalEqual++;
      }
    }
  }
  double percentEqual = ((double) totalEqual) / ((double) left.width * totalWindowSize) * 100.0;
  return percentEqual;
}

boolean isCloseEnough(color a, color b) {
   float ra = a >> 16 & 0xFF;
   float ga = a >> 8 & 0xFF;
   float ba = a & 0xFF;
   
   float rb = b >> 16 & 0xFF;
   float gb = b >> 8 & 0xFF;
   float bb = b & 0xFF;
   
   return abs(ra - rb) < ALLOWABLE_PIXEL_COLOR_DIFFERENCE && 
          abs(ga - gb) < ALLOWABLE_PIXEL_COLOR_DIFFERENCE && 
          abs(ba - bb) < ALLOWABLE_PIXEL_COLOR_DIFFERENCE;
}