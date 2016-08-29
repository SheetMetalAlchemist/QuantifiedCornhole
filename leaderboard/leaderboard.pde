import controlP5.*;

ControlP5 cp5;

Table table;

PImage bg;
PImage gradient;
PImage bg_mask;
PImage twitter;
PImage left;
PImage right;

int currentRow; 
float rank = 0.0;

int buffer = 10;
float height_adj = 4795.0;
float heightComp, fracComp, heightRef;
float compLineXpos;

int[] affiliation = new int[buffer];
int[] score = new int[buffer];
int[] refFlag = new int[buffer];
float[] velAvg = new float[buffer];
float[] parabFactor = new float[buffer];
String[] name = new String[buffer];
float[] jitter = new float[buffer];

float[] curve1x = new float[1050];
float[] curve1y = new float[1050];

String affil = "Other";
String velocityComp = "0.0";
String velocityRef = "0.0";

int time;
int wait = 5000;
int k = 0;


void setup() {
  fullScreen();

  PFont font = createFont("arial", 25);
  twitter = loadImage("twitter.png");
  left = loadImage("left.png");
  right = loadImage("right.png");

  cp5 = new ControlP5(this);

  cp5.addButton("twitterMenu")
    .setPosition(1500, 140)
    .setImages(twitter, twitter, twitter)
    .updateSize()
    ;

  cp5.addButton("left")
    .setPosition(1650, 140)
    .setImages(left, left, left)
    .updateSize()
    ;

  cp5.addButton("right")
    .setPosition(1750, 140)
    .setImages(right, right, right)
    .updateSize()
    ;


  Group setup = cp5.addGroup("setup")
    .setPosition(1400, 2)
    .setSize(540, 230)
    .setBackgroundColor(color(0, 200))
    .setLabel("Twitter Info")
    ;

  cp5.addTextfield("Username")
    .setPosition(200, 50)
    .setSize(200, 40)
    .setFont(font)
    .setFocus(true)
    .setColor(color(255, 0, 0))
    .setGroup(setup)
    ;

  cp5.addButton("Tweet")
    .setValue(0)
    .setPosition(280, 120)
    .setSize(50, 50)
    .setGroup(setup)
    ;

  bg = loadImage("Leaderboard.png");
  gradient = loadImage("gradient.png");
  bg_mask = loadImage("bg_mask.png");
  bg.mask(bg_mask);
  time = millis();

  for (int i=0; i<buffer; i++) {
    affiliation[i] = 0;
    score[i] = 0;
    refFlag[i] = 0;
    velAvg[i] = 0.0;
    parabFactor[i] = 0.0;
    name[i] = "None";
    jitter[i] = 0.0;
  }
}

void draw() {
  image(bg, 0, 0);
  drawstatics();
  refreshTable();
  drawCompetitor(k);
  drawCurve(k);
  drawRef();
  calcPercentile(k);


  if (millis() - time >= wait) {
    if (k < buffer-1) {
      k++;
    } else {
      k = 0;
    }
    time = millis(); //also update the stored time
  }
}

void calcPercentile(int j) {
  float percentile = 0.0;
  int scoreUser = score[j];
  for (int i = 0; i < table.getRowCount(); i++) {
    if (table.getInt(i, "Score") <= scoreUser) {
      //println(table.getInt(i, "Score"));
      rank++;
    } else {
      //println("no change");
    }
  }
  int totalRows = table.getRowCount();
  percentile = (rank / totalRows) * 100;
  int percent = floor(percentile);
  fill(0);
  textSize(20);
  text(percent, 985, 200);  
  rank = 0;
}

void drawRef () {
  TableRow refRow = table.findRow("1", "Reference Throw");

  velocityRef = refRow.getString("Avg. Velocity");

  fill(154, 65, 175);
  textSize(20);
  heightRef = refRow.getFloat("Last Throw ParabParam")*height_adj;
  text(heightRef, 255, 150);

  textSize(60);
  if (velocityRef.length() < 4) {
    text(velocityRef, 300, 600);
  } else {
    text(velocityRef.substring(0, 4), 300, 600);
  }

  stroke(154, 65, 175);
  computeParab(refRow.getFloat("Last Throw ParabParam"));
  drawParab(refRow.getFloat("Jitter"));
}

void drawCompetitor(int j) {
  fill(0, 21, 255);
  textSize(20);
  textAlign(CENTER, BOTTOM);
  text(name[j], 130, 520);
  text(name[j], 1600, 600);


  stroke(0, 21, 255);
  heightComp = parabFactor[j]*height_adj;
  fracComp = heightComp / heightRef;
  compLineXpos = map(fracComp, 0.8, 1.2, 100, 420);
  if (compLineXpos < 100) {
    compLineXpos = 100;
  }
  if (compLineXpos > 420) {
    compLineXpos = 420;
  }
  line(compLineXpos, 160, compLineXpos, 285);
  text(heightComp, compLineXpos, 150); 
  text(name[j], compLineXpos, 315);


  fill(0);
  text(affilDecode(affiliation[j]), 762, 200);
  text(score[j], 1325, 200);
  text("/8", 1342, 200);
  text(floor(fracComp*100), 470, 215);

  velocityComp = str(velAvg[j]);

  fill(0, 21, 255);
  textSize(60);
  if (velocityComp.length() < 4) {
    text(velocityComp, 125, 600);
  } else {
    text(velocityComp.substring(0, 4), 125, 600);
  }
}

void drawstatics() {
  textAlign(LEFT, BOTTOM);
  image(gradient, 100, 150);
  fill(154, 65, 175);
  textSize(20);
  text("Best", 240, 315);
  text("Best", 280, 520);
  text("Best", 1580, 550);
  fill(0);
  text("Height", 25, 225);
  text("%", 490, 215);
  text("of Best", 440, 240);
  text("Avg. Throw Velocity", 120, 450);
  text("(ft/sec)", 180, 480);
  textSize(25);
  text("Affiliation:", 700, 170);
  text("Ranking:", 1000, 170);
  text("Score:", 1300, 170);
  textSize(20);
  text("th Percentile", 1000, 200);
}

void refreshTable() {
  table = loadTable("Michigan.csv", "header");
  table.trim();
  if (table.getRowCount() <= buffer) {
    for (int i = 0; i < table.getRowCount(); i++) {
      name[i] = table.getString(i, "Name");
      parabFactor[i] = table.getFloat(i, "Last Throw ParabParam");
      velAvg[i] = table.getFloat(i, "Avg. Velocity");
      refFlag[i] = table.getInt(i, "Reference Throw");
      score[i] = table.getInt(i, "Score");
      affiliation[i] = table.getInt(i, "Affiliation");
      jitter[i] = table.getFloat(i, "Jitter");
    }
  } else {
    int m = 0;
    int tableLastRow = 0;
    tableLastRow = table.getRowCount();
    for (int j = buffer; j > 0; j--) {
      name[m] = table.getString((tableLastRow-j), "Name");
      parabFactor[m] = table.getFloat((tableLastRow-j), "Last Throw ParabParam");
      velAvg[m] = table.getFloat((tableLastRow-j), "Avg. Velocity");
      refFlag[m] = table.getInt((tableLastRow-j), "Reference Throw");
      score[m] = table.getInt((tableLastRow-j), "Score");
      affiliation[m] = table.getInt((tableLastRow-j), "Affiliation");
      jitter[m] = table.getFloat((tableLastRow-j), "Jitter");
      m++;
    }
  }
}

String affilDecode(int affilCode) {
  if (affilCode == 1) {
    affil = "Michigan";
  }
  if (affilCode == 2) {
    affil = "Northwestern";
  }
  if (affilCode == 3) {
    affil = "Other";
  }
  return affil;
}

void drawCurve(int j) {
  stroke(0, 21, 255);
  computeParab(parabFactor[j]);
  drawParab(jitter[j]);
}

void computeParab(float a) {
  for (float x = -600; x < 450; x++)
  {
    float y = a*(x-625)*(x+775);
    curve1x[int(x+600)] = x;
    curve1y[int(x+600)] = y;
  }
}

void drawParab(float curve3r) {
  pushMatrix();
  translate(1050, 1300);
  rotate(radians(10*curve3r));
  strokeWeight(4);
  for (int i = 0; i < 900; i++) 
  {   
    point(curve1x[i], curve1y[i]);
  }
  popMatrix();
}

public void Tweet() {
  String nameValue = cp5.get(Textfield.class, "Username").getText();
  cp5.getGroup("setup").close();
  save(nameValue+".png");
  wait = 5000;
}

public void twitterMenu() {
  cp5.getGroup("setup").open();
  wait = 50000;
}

public void left() {
  if (k > 0) {
    k--;
  } else {
    k = 0;
  }
}

public void right() {
  if (k < buffer - 1) {
    k++;
  } else {
    k = buffer-1;
  }
}