/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import java.util.List;

List<PImage> images = new ArrayList<PImage>();
PImage img1;
PImage img2;
PImage output;
final double MINIMUM_OVERLAP = 12.0;
final double IOS_HEADER_RATIO = 0.100;
final double AND_HEADER_RATIO = 0.125;
int HEADER_HEIGHT;
PrintWriter writer;
int currentDisplayY;

void setup() {
 //size(1080, 3500);
 background(0);
 fullScreen();
 noStroke();
 fill(0);
 
 //images.add(loadImage("and-m-1.png"));
 //images.add(loadImage("and-m-2.png"));
 //images.add(loadImage("and-m-3.png"));
 images.add(loadImage("i1.PNG"));
 images.add(loadImage("i2.PNG"));
 images.add(loadImage("i3.PNG"));
 images.add(loadImage("i4.PNG"));
 //images.add(loadImage("i5.PNG"));
 //images.add(loadImage("i6.PNG"));
 //images.add(loadImage("kry1.png"));
 //images.add(loadImage("kry2.png"));
 //images.add(loadImage("kry3.png"));
 
 HEADER_HEIGHT = (int) (((double) images.get(0).height) * IOS_HEADER_RATIO);
 println((double) images.get(0).height);
 println(HEADER_HEIGHT);
 for (int i=0; i<images.size() - 1; i++) {
   if (img1 == null) {
     img1 = images.get(i);
     img1.loadPixels();
   }
   img2 = images.get(i+1);  
   img2.loadPixels();
   int idealOverlapWindowHeight = calculateOverlap(i);
   PImage newImage = createNewImage(idealOverlapWindowHeight);
   img1 = newImage;//.copy();
 }

 //float shrinkRatio = displayHeight / img1.height;
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
  if (currentDisplayY < -(img1.height - displayHeight)) {
   currentDisplayY = -(img1.height - displayHeight); 
  }
  background(255);
  image(img1, (displayWidth - img1.width) / 2, currentDisplayY, img1.width, img1.height);
}

int calculateOverlap(int iter) {
 writer = createWriter("PercentEquality" + iter + ".csv");
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
 if(maxPercentEquality < MINIMUM_OVERLAP) {
   idealOverlapWindowHeight = HEADER_HEIGHT;
 }
 
 println("Proposed window height for optimal overlap: " + idealOverlapWindowHeight);
 println("Percent equality is now : "+ maxPercentEquality);
 writer.flush();
 writer.close();
 
 return idealOverlapWindowHeight;
}

PImage createNewImage(int idealOverlapWindowHeight) {
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
      if (left.pixels[left.width * leftRowNumber + x] == 
              right.pixels[right.width * rightRowNumber + x]) {
        totalEqual++;
      }
    }
  }
  double percentEqual = ((double) totalEqual) / ((double) left.width * totalWindowSize) * 100.0;
  return percentEqual;
}