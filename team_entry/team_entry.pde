import controlP5.*;
import java.util.ArrayList;
import KinectPV2.KJoint;
import KinectPV2.*;

int twitterTimer = 3;
int twitterFlag = 0;
int snap = 0;
String savePath = "C:\\Users\\Sean\\Copy\\Sheet Metal Alchemist\\ge_ch\\Cornhole1";

KinectPV2 kinect;

//SPC Variables from here down
PImage kinectDepth;
PImage kinectMask;
int hZoom = 1300; //CHANGE THIS TO ADJUST KINECT HORIZ POSITION ON SCREEN
int vZoom = 600; //CHANGE THIS TO ADJUST KINECT VERT POSITION ON SCREEN

ControlP5 cp5;
PImage homeImg, awayImg, otherImg;
PImage homeImgInv, awayImgInv, otherImgInv;
PImage homeSm, awaySm, otherSm;
PImage jerseyIcon;
PImage bg;
String nameValue = "";
int team = 0;
int score = 0;
float sensorDist = 2.0; //distance between sensors in feet, should not change
long time1, time2; //time readings from distance sensors
int sensRead; //read activeSens reading
float timeDiffMillis;
float timeDiff;

Table table;

float[] parabFactor = { 0.0, 0.0, 0.0 };

int[] staticLoc = { 250, 550, 850, 1050 };

float[] velocity = { 0.0, 0.0, 0.0 };

int sens1loc = 0; //Sensor data being sent via arduino - sensor 0 is closest to the thrower
int sens2loc = 2; //Sensor data being sent via arduino - sensor 4 is furthest from thrower
int activeSens = sens2loc; //The sensor which is being used to compute the parabola

MarkerSphere s0 = new MarkerSphere(staticLoc[0]);
MarkerSphere s1 = new MarkerSphere(staticLoc[1]);
MarkerSphere s2 = new MarkerSphere(staticLoc[2]);
MarkerSphere s3 = new MarkerSphere(staticLoc[3]);

float[] curve1x = new float[1050];
float[] curve1y = new float[1050];
float[] curve2x = new float[1050];
float[] curve2y = new float[1050];
float[] curve3x = new float[1050];
float[] curve3y = new float[1050];
float curve1r = 0;
float curve2r = 0;
float curve3r = 0;

float rr0 = 0;
float rr1 = 0;
float rr2 = 0;
float rr3 = 0;

int refFlag = 0;

void setup() {
  fullScreen(P3D);

  //kinect commands to load skeleton tracking
  kinect = new KinectPV2(this);
  kinect.enableSkeletonDepthMap(true);
  // kinect.enableBodyTrackImg(true);
  // kinect.enableDepthMaskImg(true);
  kinect.init();

  table = loadTable("\\Perdue.csv", "header");

  bg = loadImage("cornhole_bg.png");
  homeImg = loadImage("home.png");
  homeImgInv = loadImage("homeInv.png");
  awayImg = loadImage("away.png");
  awayImgInv = loadImage("awayInv.png");
  otherImg = loadImage("other.png");
  otherImgInv = loadImage("otherInv.png");
  homeSm = loadImage("homesm.png");
  awaySm = loadImage("awaysm.png");
  otherSm = loadImage("othersm.png");

  PFont font = createFont("arial", 25);

  cp5 = new ControlP5(this);

  Group setup = cp5.addGroup("setup")
    .setPosition(480, 108)
    .setSize(1440, 700)
    .setBackgroundColor(color(0, 100))
    .setLabel("Game Setup")
    ;

  cp5.addButton("home")
    .setPosition(100, 50)
    .setImages(homeImg, homeImg, homeImgInv)
    .updateSize()
    .setGroup(setup)
    ;

  cp5.addButton("away")
    .setPosition(550, 50)
    .setImages(awayImg, awayImg, awayImgInv)
    .updateSize()
    .setGroup(setup)
    ;

  cp5.addButton("other")
    .setPosition(1000, 50)
    .setImages(otherImg, otherImg, otherImgInv)
    .updateSize()
    .setGroup(setup)
    ;

  cp5.addTextfield("name")
    .setPosition(635, 520)
    .setSize(200, 40)
    .setFont(font)
    .setFocus(true)
    .setColor(color(255, 0, 0))
    .setGroup(setup)
    ;

  cp5.addButton("begin")
    .setValue(0)
    .setPosition(710, 600)
    .setSize(50, 50)
    .setGroup(setup)
    ;

  cp5.addButton("reset")
    .setValue(0)
    .setPosition(645, 600)
    .setSize(50, 50)
    .setGroup(setup)
    ;

  cp5.addButton("save")
    .setValue(0)
    .setPosition(775, 600)
    .setSize(50, 50)
    .setGroup(setup)
    ;
}

void draw() {
  background(bg);
  displayTeam(team);
  displayScore(); //Also puts out static throw velocity info
  displayVelocity();
  drawParab();
  if (snap == 1) {
    save(savePath+"\\"+nameValue.substring(1)+".png");
    snap = 0;
  }
  
  //get the skeletons as an Arraylist of KSkeletons
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonDepthMap();

  //individual joints
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i);
    //if the skeleton is being tracked compute the skleton joints
    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();

      fill(0, 0, 255); //fill of the skeleton
      stroke(0, 0, 0); //stroke of the skeleton...hand color is set below

      pushMatrix();
      translate(hZoom, vZoom);
      drawBody(joints);
      drawHandState(joints[KinectPV2.JointType_HandRight]);
      drawHandState(joints[KinectPV2.JointType_HandLeft]);
      popMatrix();
    }
  }
}

void parseArduino() {
  String arduinoInput = "65,186532,0,98565,";

  int dist1Index = arduinoInput.indexOf(",");
  int dist1 = int(arduinoInput.substring(0, dist1Index));
  //println(dist1);

  int t1Index = arduinoInput.indexOf(",", dist1Index+1);
  long t1 = Long.parseLong(arduinoInput.substring(dist1Index+1, t1Index));
  //println(t1);

  int dist2Index = arduinoInput.indexOf(",", t1Index+1);
  int dist2 = int(arduinoInput.substring(t1Index+1, dist2Index));
  //println(dist2);

  int t2Index = arduinoInput.indexOf(",", dist2Index+1);
  long t2 = Long.parseLong(arduinoInput.substring(dist2Index+1, t2Index));
  //println(t2);


  //Calculate time difference, and account for errors
  if (t2 > t1) {
    if (t2 < t1 + 3000) {
      timeDiffMillis = int(t2 - t1);
    } else {
      timeDiffMillis = round(1000*random(0.7, 1.3)*((sens2loc - sens1loc)*sensorDist)/9);
    }
  } else {
    timeDiffMillis = round(1000*random(0.7, 1.3)*((sens2loc - sens1loc)*sensorDist)/9);
  }

  //Calculate parabola height, and account for errors

  if (activeSens == sens1loc) {
    if (dist1 < 140) {
      if (dist1 > 12) {
        parabFactor[0] = (0.0017/72)*dist1;
      } else {
        parabFactor[0] = (0.0017)*random(0.85, 1.2);
      }
    } else {
      parabFactor[0] = 0.0017*random(0.85, 1.2);
    }
  }

  if (activeSens == sens2loc) {
    if (dist2 < 140) {
      if (dist2 > 12) {
        parabFactor[0] = (0.0017/72)*dist2;
      } else {
        parabFactor[0] = 0.0017*random(0.85, 1.2);
      }
    } else {
      parabFactor[0] = 0.0017*random(0.85, 1.2);
    }
  }
  updateVelocity();
  computeParab();
}

void updateVelocity() {
  velocity[2] = velocity[1];
  velocity[1] = velocity[0];
  timeDiff = timeDiffMillis/1000; //convert from millis to sec here
  velocity[0] = ((sens2loc - sens1loc)*sensorDist)/timeDiff;
}

void displayVelocity() {
  textSize(48);
  fill(20);
  text(velocity[0], 68, 475);
  fill(20, 50);
  text(velocity[1], 68, 525);
  fill(20, 25);
  text(velocity[2], 68, 575);
}

void computeParab() {
  parabFactor[2] = parabFactor[1];
  parabFactor[1] = parabFactor[0];
  //parabFactor[0] = sensRead/((staticLoc[activeSens]-450)*(staticLoc[activeSens]+450)); USE ME IN PRODUCTION, ADD ONSITE
  //parabFactor[0] = 0.0020*random(0.9, 1.1);

  for (int i = 0; i < 950; i++) 
  {  
    curve3x[i] = curve2x[i];
    curve2x[i] = curve1x[i];
    curve3y[i] = curve2y[i];
    curve2y[i] = curve1y[i];
  }

  curve3r = curve2r;
  curve2r = curve1r;
  curve1r = random(0.7, 1.3);

  rr3 = random(0.9, 1.1);
  rr2 = random(0.9, 1.1);
  rr1 = random(0.9, 1.1);
  rr0 = random(0.9, 1.1);

  for (float x = -600; x < 450; x++)
  {
    float y = parabFactor[0]*(x-625)*(x+775);
    curve1x[int(x+600)] = x;
    curve1y[int(x+600)] = y;
  }
}

void drawParab() {
  pushMatrix();
  translate(staticLoc[2]+175, 1300);
  rotate(radians(10*curve1r));
  stroke(255, 0, 0);
  for (int i = 0; i < 900; i++) 
  {   
    point(curve1x[i], curve1y[i]);
  }
  translate(-800, 0);
  s0.update(round(rr0*curve1y[100]));
  s1.update(round(rr1*curve1y[350]));
  s2.update(round(rr2*curve1y[700]));
  s3.update(round(rr3*curve1y[900]));
  popMatrix();



  pushMatrix();
  translate(staticLoc[2]+175, 1300);
  rotate(radians(10*curve2r));
  stroke(0, 25);
  for (int i = 0; i < 900; i++) 
  {   
    point(curve2x[i], curve2y[i]);
  }
  popMatrix();



  pushMatrix();
  translate(staticLoc[2]+175, 1300);
  rotate(radians(10*curve3r));
  stroke(0, 5);
  for (int i = 0; i < 900; i++) 
  {   
    point(curve3x[i], curve3y[i]);
  }
  popMatrix();
}

void displayScore() {
  textSize(48);
  fill(20);
  text("Score", 275, 215);
  text(score, 325, 300);
  textSize(18);
  text("Throw Velocity", 255, 500);
  text("(ft/sec)", 290, 525);
}

void keyPressed() {
  if (key == '+') {
    score++;
  }
  if (key == '-') {
    score--;
  }
  if (key == 'u') {
    parseArduino();
    if (twitterFlag == 1) {
      if (twitterTimer == 0) {
        snap = 1;
        twitterFlag = 0;
      }
      twitterTimer--;
    }
  }
  if (key == '*') {
    refFlag = 1;
  }
}

void displayTeam(int selTeam) {
  switch(selTeam) {
  case 1:
    image(homeSm, 20, 150);
    break;

  case 2:
    image(awaySm, 20, 150);
    break;

  default:
    image(otherSm, 20, 150);
    break;
  }
}

public void home() {
  println("Home Team");
  team = 1;
}

public void away() {
  println("Away Team");
  team = 2;
}

public void other() {
  println("Other Team");
  team = 3;
}

public void reset() {
  velocity[0] = 0.0;
  velocity[1] = 0.0;
  velocity[2] = 0.0;
  score = 0;
  for (int i = 0; i<1050; i++) {
    curve1x[i] = 0;
    curve1y[i] = 0;
    curve2x[i] = 0;
    curve2y[i] = 0;
    curve3x[i] = 0;
    curve3y[i] = 0;
  }
  refFlag = 0;
}

public void save() {

  TableRow newRow = table.addRow();
  newRow.setString("Name", cp5.get(Textfield.class, "name").getText());
  newRow.setInt("Affiliation", team);
  newRow.setInt("Score", score);
  newRow.setFloat("Avg. Velocity", (velocity[0]+velocity[1]+velocity[2])/3);
  newRow.setFloat("Last Throw ParabParam", parabFactor[2]);
  newRow.setInt("Reference Throw", refFlag);
  newRow.setFloat("Jitter", curve3r);

  saveTable(table, "data/Perdue.csv");
}

public void begin() {
  nameValue = cp5.get(Textfield.class, "name").getText();
  println(nameValue);
  
  int firstChar = nameValue.indexOf("@");
  if (firstChar == 0) {
    //println("Worked!");
    twitterFlag = 1;
    twitterTimer = 3;
  } else {
    twitterFlag = 0;
  }
  cp5.getGroup("setup").close();
}

class MarkerSphere {
  int diam1 = 20;
  int diam2 = 60;
  int loc;
  MarkerSphere (int xloc) {
    loc = xloc;
  }
  void update(int ypos) {
    ellipseMode(CENTER);
    stroke(50);
    strokeWeight(2);
    fill(0, 150, 255, 80);
    ellipse(loc, ypos, diam1, diam1);
    noFill();
    strokeWeight(4);
    ellipse(loc, ypos, diam2, diam2);
  }
}


//KINECT_FUNC draw the body
void drawBody(KJoint[] joints) {
  drawBone(joints, KinectPV2.JointType_Head, KinectPV2.JointType_Neck);
  drawBone(joints, KinectPV2.JointType_Neck, KinectPV2.JointType_SpineShoulder);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_SpineMid);
  drawBone(joints, KinectPV2.JointType_SpineMid, KinectPV2.JointType_SpineBase);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderRight);
  drawBone(joints, KinectPV2.JointType_SpineShoulder, KinectPV2.JointType_ShoulderLeft);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipRight);
  drawBone(joints, KinectPV2.JointType_SpineBase, KinectPV2.JointType_HipLeft);

  // KINECT_FUNC Right Arm
  drawBone(joints, KinectPV2.JointType_ShoulderRight, KinectPV2.JointType_ElbowRight);
  drawBone(joints, KinectPV2.JointType_ElbowRight, KinectPV2.JointType_WristRight);
  drawBone(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_HandRight);
  drawBone(joints, KinectPV2.JointType_HandRight, KinectPV2.JointType_HandTipRight);
  drawBone(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_ThumbRight);

  // KINECT_FUNC Left Arm
  drawBone(joints, KinectPV2.JointType_ShoulderLeft, KinectPV2.JointType_ElbowLeft);
  drawBone(joints, KinectPV2.JointType_ElbowLeft, KinectPV2.JointType_WristLeft);
  drawBone(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_HandLeft);
  drawBone(joints, KinectPV2.JointType_HandLeft, KinectPV2.JointType_HandTipLeft);
  drawBone(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_ThumbLeft);

  // KINECT_FUNC Right Leg
  drawBone(joints, KinectPV2.JointType_HipRight, KinectPV2.JointType_KneeRight);
  drawBone(joints, KinectPV2.JointType_KneeRight, KinectPV2.JointType_AnkleRight);
  drawBone(joints, KinectPV2.JointType_AnkleRight, KinectPV2.JointType_FootRight);

  // KINECT_FUNC Left Leg
  drawBone(joints, KinectPV2.JointType_HipLeft, KinectPV2.JointType_KneeLeft);
  drawBone(joints, KinectPV2.JointType_KneeLeft, KinectPV2.JointType_AnkleLeft);
  drawBone(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_FootLeft);

  //KINECT_FUNC Single joints
  drawJoint(joints, KinectPV2.JointType_HandTipLeft);
  drawJoint(joints, KinectPV2.JointType_HandTipRight);
  drawJoint(joints, KinectPV2.JointType_FootLeft);
  drawJoint(joints, KinectPV2.JointType_FootRight);

  drawJoint(joints, KinectPV2.JointType_ThumbLeft);
  drawJoint(joints, KinectPV2.JointType_ThumbRight);

  drawJoint(joints, KinectPV2.JointType_Head);
}

//KINECT_FUNC draw a single joint
void drawJoint(KJoint[] joints, int jointType) {
  pushMatrix();
  translate(joints[jointType].getX(), joints[jointType].getY(), joints[jointType].getZ());
  ellipse(0, 0, 25, 25);
  popMatrix();
}

//KINECT_FUNC draw a bone from two joints
void drawBone(KJoint[] joints, int jointType1, int jointType2) {
  pushMatrix();
  translate(joints[jointType1].getX(), joints[jointType1].getY(), joints[jointType1].getZ());
  ellipse(0, 0, 25, 25);
  popMatrix();
  line(joints[jointType1].getX(), joints[jointType1].getY(), joints[jointType1].getZ(), joints[jointType2].getX(), joints[jointType2].getY(), joints[jointType2].getZ());
}

//KINECT_FUNC draw a ellipse depending on the hand state
void drawHandState(KJoint joint) {
  noStroke();
  fill(0, 255, 0);
  pushMatrix();
  translate(joint.getX(), joint.getY(), joint.getZ());
  ellipse(0, 0, 70, 70);
  popMatrix();
}