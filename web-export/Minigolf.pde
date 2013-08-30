
import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;


// audio stuff

Maxim maxim;
AudioPlayer[] wallSounds;
AudioPlayer holeSound;
AudioPlayer hitSound;
AudioPlayer drivebySound;

int whichSoundLooper = 0;
float ballRadius = 10;
float holeRadius = 20;

Physics physics;

Body[] block = new Body[0];

Body[] balls;

PImage groundImg;
PImage holeImg;
PImage startingPointImg;
PImage submitImg;
PImage restartImg;
PImage restartIconImg;
PImage hillImg;
PImage hillLeftImg;
PImage hillRightImg;
PImage groundEmmiImg;
PImage bahnImg;
PImage gleisImg;
PImage eichhoernchenImg;
PImage eichhofImg;
PImage emmiImg;
PImage pilatusImg;

PVector [] mouseVecHistory;
PVector mouseVec;

PVector hole;
PVector startingPoint;

int counter = 0;
int timeCounter = 0;

float[] gameData = new float[0];


Boolean inHole = false;

int hitDelay = 60;
int hitDelayCounter = hitDelay;
Boolean pointerWasOutside = false;


// a handler that will detect collisions
CollisionDetector detector; 


float mouseXTr;
float mouseYTr;
float pmouseXTr;
float pmouseYTr;


// this is used to remember that the user 
// has triggered the audio on iOS... see mousePressed below
boolean userHasTriggeredAudio = false;



// define levels

boolean levelRunning = false;

int currentLevel = 0;



void setup() {
  size(520, 800);
  //size (window.innerWidth, window.innerHeight);
  //size(520, 500);
  
  OnResizeDocument();
  
  frameRate(60);
  imageMode(CENTER);

  //initScene();

  /*
   * Set up a physics world. This takes the following parameters:
   * 
   * parent The PApplet this physics world should use
   * gravX The x component of gravity, in meters/sec^2
   * gravY The y component of gravity, in meters/sec^2
   * screenAABBWidth The world's width, in pixels - should be significantly larger than the area you intend to use
   * screenAABBHeight The world's height, in pixels - should be significantly larger than the area you intend to use
   * borderBoxWidth The containing box's width - should be smaller than the world width, so that no object can escape
   * borderBoxHeight The containing box's height - should be smaller than the world height, so that no object can escape
   * pixelsPerMeter Pixels per physical meter
   */
  physics = new Physics(this, width, height, 0, 0/*-30*/, width*2, height*2, width, height, 100);
  // this overrides the debug render of the physics engine
  // with the method myCustomRenderer
  // comment out to use the debug renderer 
  // (currently broken in JS)
  physics.setCustomRenderingMethod(this, "myCustomRenderer");

  physics.setRestitution(.4);
  groundImg = loadImage("platz-k.jpg");
  groundEmmiImg = loadImage("platz-k-emmi.jpg");
  holeImg = loadImage("hole.png");
  startingPointImg = loadImage("starting-point.png");
  submitImg = loadImage("submit.png");
  restartImg = loadImage("restart.png");
  restartIconImg = loadImage("restart-icon.png");
  hillImg = loadImage("hill.jpg");
  bahnImg = loadImage("bahn.png");
  gleisImg = loadImage("gleis.png");
  eichhoernchenImg = loadImage("eichhoernchen.png");
  eichhofImg = loadImage("eichhof.png");
  emmiImg = loadImage("emmi.png");
  pilatusImg = loadImage("pilatus.png");
  
  mouseVecHistory = new PVector[5];
  for (int i=0;i<mouseVecHistory.length;i++)
  {
    mouseVecHistory[i]= new PVector(0, 0);
  }
  mouseVec = new PVector(0, 0);

  hole = new PVector(width/2, height/5);
  startingPoint = new PVector(width/2, height*.8);

  balls = new Body[0];

  // init sounds
  maxim = new Maxim(this);

  wallSounds = new AudioPlayer[balls.length];
  for (int i=0;i<5;i++) {
    wallSounds[i] = maxim.loadFile("wall.mp3");
  }

  holeSound = maxim.loadFile("hole.mp3");
  hitSound = maxim.loadFile("hit.mp3");
  drivebySound = maxim.loadFile("driveby.mp3");


  // collision callbacks
  detector = new CollisionDetector (physics, this);

  startNextLevel();
}


void draw() {
  // remap mouse positions to match the size of the canvas
  float widthRatio = width / getCanvasWidth();
  mouseXTr = widthRatio * mouseX;
  pmouseXTr = widthRatio * pmouseX;
  float heightRatio = height / getCanvasHeight();
  mouseYTr = heightRatio * mouseY;
  pmouseYTr = heightRatio * pmouseY;
    
  timeCounter++;
  
  // draw main background
  if (currentLevel == 7) image(groundEmmiImg, width/2, height/2);
  else image(groundImg, width/2, height/2);


  // for mouse-controlled devices: calculate mouse direction with a buffer based on vectors (average of recent mouse motions)
  if ((mouseYTr != pmouseYTr || mouseXTr != pmouseXTr) && !Modernizr.touch) {
    mouseVecHistory = append(mouseVecHistory, new PVector(mouseYTr - pmouseYTr, mouseXTr - pmouseXTr));
    mouseVecHistory = reverse(shorten(reverse(mouseVecHistory)));
    mouseVec.set(0, 0);
    for (i = 0; i < mouseVecHistory.length; i++) {
      mouseVec.add(mouseVecHistory[i]);
    }
  }

  drawLevel();

  if (inHole) {
    // draw ball in hole
    noStroke();
    pushMatrix();
    translate(hole.x, hole.y);
    // (shadow)
    pushMatrix();
    fill(0, 70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.2, ballRadius*2.2);
    popMatrix();
    // (main)
    fill(42, 35, 0);
    ellipse(0, 0, ballRadius*2, ballRadius*2);
    // (reflection)
    translate(-ballRadius/2, -ballRadius/2);
    fill(60);
    ellipse(0, 0, ballRadius/3, ballRadius/2);
    popMatrix();
  }
  
  // ball-specific code:
  hitDelayCounter++;
  for (i = 0; i < balls.length; i++) {
    Vec2 ballPos = physics.worldToScreen(balls[i].getWorldCenter());
    float speed = sqrt(sq((balls[i].getLinearVelocity().x) + sq(balls[i].getLinearVelocity().y)));
    if (currentLevel != 0 && currentLevel != 10) {

      // gravity when close to the hole
      if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * 1.5 && dist(ballPos.x, ballPos.y, hole.x, hole.y) >= holeRadius * .7) {
        //float force = sq(ballRadius) * .001 / (20 / (holeRadius / 4));
        float force = 0.1 *  (sq(ballRadius) / 100) * (holeRadius / 20) * (speed/10 + 1) / (1 + pow(3, -((holeRadius * 1.5) - dist(ballPos.x, ballPos.y, hole.x, hole.y))/10));
        Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
        
        drivebySound.volume(20);
        drivebySound.play();
      }
      else drivebySound.cue(0);
      
      if (currentLevel == 6 && dist(ballPos.x, ballPos.y, hole.x, hole.y) > 52 && dist(ballPos.x, ballPos.y, hole.x, hole.y) < 145) {
        float force = 0.03;
        Vec2 impulse =  new Vec2(-(hole.x-ballPos.x), -(hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      if (currentLevel == 6 && dist(ballPos.x, ballPos.y, hole.x, hole.y) <= 52 && dist(ballPos.x, ballPos.y, hole.x, hole.y) > holeRadius * 1.5) {
        float force = 0.06;
        Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      
      if (currentLevel == 7 && dist(ballPos.x, ballPos.y, 322, 393) < 65) {
        float force = 0.03 * dist(ballPos.x, ballPos.y, 322, 393) / 65;
        Vec2 impulse =  new Vec2((ballPos.x-322), (ballPos.y-393));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      if (currentLevel == 7 && dist(ballPos.x, ballPos.y, 163, 525) < 65) {
        float force = 0.07 * dist(ballPos.x, ballPos.y, 163, 525) / 65;
        Vec2 impulse =  new Vec2((ballPos.x-163), (ballPos.y-525));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }

      // ball drops in hole
      if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * .7  && speed <= 4.5) {
        //println("Won  " + speed);
        physics.getWorld().DestroyBody(balls[i]);
        balls = concat(subset(balls, 0, i), subset(balls, i+1, balls.length));
        inHole = true;
        levelRunning = false;
        holeSound.cue(0);
        holeSound.volume(15);
        holeSound.play();
        drivebySound.stop();
      }
    }


    // draw balls
    noStroke();
    pushMatrix();
    translate(ballPos.x, ballPos.y);
    // (shadow)
    pushMatrix();
    fill(0, 70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.2, ballRadius*2.2);
    popMatrix();
    // (main)
    fill(249, 230, 149);
    ellipse(0, 0, ballRadius*2, ballRadius*2);
    // (reflection)
    translate(-ballRadius/2, -ballRadius/2);
    fill(255);
    ellipse(0, 0, ballRadius/3, ballRadius/2);
    popMatrix();


    // apply and count hit
    if (hitDelayCounter > hitDelay && speed <= .025 * ballRadius)
    {
      if (dist(mouseXTr, mouseYTr, ballPos.x, ballPos.y) <= 30) {
        if (pointerWasOutside) {
          Vec2 impulse = new Vec2(mouseVec.y*.0004*sq(ballRadius), mouseVec.x*.0004*sq(ballRadius));
          balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
          if (currentLevel != 0 && currentLevel != 10) counter++;
          hitDelayCounter = 0;
          pointerWasOutside = false;
          
          hitSound.cue(0);
          hitSound.volume(sqrt(sqrt(sq(mouseVec.x) + sq(mouseVec.y))));
          hitSound.play();

          
          if (currentLevel != 0 && currentLevel != 10) {
            gameData = append(gameData, timeCounter);
            gameData = append(gameData, impulse.x);
            gameData = append(gameData, impulse.y);
            gameData = append(gameData, currentLevel);
          }
        }
        else {
          textSize(16);
          textAlign(CENTER);
          PFont mono;
          mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
          textFont(mono);
          fill(0);
          text("Schläger ausholen und schiessen", mouseXTr, mouseYTr-50);
        }
      }
      else {
        if (pmouseXTr != mouseXTr && pmouseYTr != mouseYTr) {
          pointerWasOutside = true;
        }
      }

      // draw the putter
      pushMatrix();
      translate(mouseXTr, mouseYTr);
      rotate(atan(mouseVec.x/mouseVec.y));
      fill(200);
      //stroke(0);
      rect(-5, -15, 10, 30,3);
      fill(0);
      rect(-1, 0, 2, 15,1);
      fill(255,0,0);
      ellipse(0,15,6,6);
      noStroke();
      popMatrix();
    }
    else {
      textSize(16);
      textAlign(CENTER);
      PFont mono;
      mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
      textFont(mono);
      fill(0);
      text("Warten bis Ball hält...", mouseXTr, mouseYTr-50);
    }
  }
  

  if (currentLevel != 0 && currentLevel != 10) {
    textSize(24);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);

    // draw the hit counter & level indicator
    fill(255);
    textAlign(RIGHT);
    text("Schläge: " + counter, width-20, 30);
    textAlign(LEFT);
    text("Bahn " + currentLevel, 20, 30);

    if (!levelRunning) {
      textAlign(CENTER);
      fill(0);
      text("Klicken für nächste Bahn", width/2+1, height/2+1);
      fill(255);
      text("Klicken für nächste Bahn", width/2, height/2);
    }
  }
}



void drawLevel() {
  
  noStroke();

  if (currentLevel != 0 && currentLevel != 10) {
    // draw hole and starting point
    image(holeImg, hole.x, hole.y);
    image(startingPointImg, startingPoint.x, startingPoint.y);
  }

  image(restartIconImg, width-60, height-20);

  
  //walls
  fill(255);
  rect(40, 40, width-80, 20); //horizontal bar
  rect(40, 40, 20, height-80); //vertical bar
  rect(40, height-60, width-80, 20); //horizontal bar
  rect(width-60, 40, 20, height-80); //vertical bar
  
  if (currentLevel == 1) {  
    imageMode(CORNER);
    image(gleisImg,60,510);
    float bahnPosX = timeCounter%600;
    if (timeCounter%600 > 300) bahnPosX = 600 - timeCounter%600;
    float bahnPosY = 480-timeCounter%600/300*77;
    if (timeCounter%600 > 300) bahnPosY = 480-(2*77-timeCounter%600/300*77);
    image(bahnImg,bahnPosX,bahnPosY);
    imageMode(CENTER);
  }
  
  if (currentLevel == 2) {
    fill(255);
    stroke(255);
    drawPolygon(diagonalProtectors);
  }

  if (currentLevel == 3) {
    fill(255);
    image(eichhoernchenImg, width/2, 300);
    image(eichhofImg, width/2, 540);
  }
  if (currentLevel == 4) {
    fill(255);
    stroke(255);
    drawPolygon(deflectorTopLeft);
    
    rectMode(CORNERS);
    rect(50,470,106,451);
    rect(170,308,228,327);
    rect(221,192,468,746);
    rectMode(CORNER);
  }
  if (currentLevel == 5) {
    fill(255);
    stroke(255);
    image(pilatusImg,260, 589);
    //drawPolygon(pilatus);
  }
  if (currentLevel == 6) {
    fill(255);
    stroke(255);
    image(hillImg, hole.x, hole.y);
    image(holeImg, hole.x, hole.y);
  }
  if (currentLevel == 7) {
    fill(255);
    stroke(255);
    image(emmiImg, 270, 370);
  }
  if (currentLevel == 8) {
    fill(255);
    stroke(255);
    drawPolygon(fiveShape);
  }
  if (currentLevel == 9) {
    fill(255);
    stroke(255);
    drawPolygon(zeroShape);
  }
  if (currentLevel == 10) {
    fill(255);
    stroke(255);
    background(255);

    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    fill(0);
    text("Resultat: " + counter + " Schläge", width/2, height/2);
    
    image(restartImg, width/2, height/2+50);
    image(submitImg, width/2, height/2+100);

  }
}

void drawPolygon(float[][] shape) {
  for (var j = 0; j < shape.length; j++) {
    beginShape();
    for (var i = 0; i < shape[j].length / 2; i++) {
      vertex(shape[j][2*i], shape[j][2*i+1]);
    }
    endShape();
  }
}

void restart() {
  currentLevel = 1;
  counter = 0;
  timeCounter = 0;
  inHole = false;
  hitDelayCounter = hitDelay;
  pointerWasOutside = false;
  levelRunning = true;
  buildLevel();
  gameData.length = 0;
}

void buildLevel() {
  // delete the old block bodies from the world
  for (i = 0; i < block.length; i++) {
    physics.getWorld().DestroyBody(block[i]);
  }
  // empty the block array
  block.length = 0;


  // set density to 0 i.e. fixed physical element
  physics.setDensity(0);



  // build the new level

  // walls
  block = append(block, physics.createRect(40, 40, 60, height-40));
  block = append(block, physics.createRect(40, 40, width-40, 60));
  block = append(block, physics.createRect(width-60, 40, width-40, height-40));
  block = append(block, physics.createRect(40, height-60, width-40, height-40));

  // default hole and starting point position
  hole = new Vec2(width/2, height*.2);
  startingPoint = new Vec2(width/2, height*.8);
  
  // Level physics
  if (currentLevel == 1) {
    hole = new Vec2(width/2, height*.2);
    startingPoint = new Vec2(width/2, height*.8);
  }
  if (currentLevel == 2) {
    hole = new Vec2(width/2, height*.2);
    startingPoint = new Vec2(width/2, height*.8);
    buildPolygonBody(diagonalProtectors);
  }
  if (currentLevel == 3) {
    hole = new Vec2(272, 203);
    startingPoint = new Vec2(111, 668);
    buildPolygonBody(eichhoernchen);
  }
  if (currentLevel == 4) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(134, 671);
    buildPolygonBody(deflectorTopLeft);
    block = append(block, physics.createRect(50,470,106,451));
    block = append(block, physics.createRect(170,308,228,327));
    block = append(block, physics.createRect(221,192,468,746));
  }
  if (currentLevel == 5) {
    hole = new Vec2(215, 654);
    startingPoint = new Vec2(364, 155);
    buildPolygonBody(pilatus);
  }
  if (currentLevel == 6) {
    hole = new Vec2(width/2, 350);
    startingPoint = new Vec2(width/2, height * .8);
  }
  if (currentLevel == 7) {
    hole = new Vec2(258, 187);//400, 120);
    startingPoint = new Vec2(263, 677);
    buildPolygonBody(fahnenschwinger);
    buildPolygonBody(kuh);
    buildPolygonBody(glocke);
    buildPolygonBody(jodler);
    buildPolygonBody(edelweiss);
    buildPolygonBody(alphorn);
  }
  if (currentLevel == 8) {
    hole = new Vec2(389, 162);
    startingPoint = new Vec2(144, 561);
    buildPolygonBody(fiveShape);
  }
  if (currentLevel == 9) {
    hole = new Vec2(260, 620);
    startingPoint = new Vec2(260, 190);
    buildPolygonBody(zeroShape);
  }

  if (currentLevel != 10) resetBall();  
}


void buildPolygonBody(float[][] polygons) {
  for (var j = 0; j < polygons.length; j++) {
    block = append(block, physics.createPolygon(polygons[j]));
  }
}


void mouseDragged() {
  // for touch-controlled devices: calculate mouse direction with a buffer based on vectors (average of recent mouse motions)
  if ((mouseYTr != pmouseYTr || mouseXTr != pmouseXTr) && Modernizr.touch) {
    mouseVecHistory = append(mouseVecHistory, new PVector(mouseYTr - pmouseYTr, mouseXTr - pmouseXTr));
    mouseVecHistory = reverse(shorten(reverse(mouseVecHistory)));
    mouseVec.set(0, 0);
    for (i = 0; i < mouseVecHistory.length; i++) {
      mouseVec.add(mouseVecHistory[i]);
    }
  }
}

void mouseMoved() {
  mouseDragged();
}


void mouseReleased() {
  // on iOS, the first audio playback has to be triggered directly by a user interaction
  if (!userHasTriggeredAudio) {
    holeSound.volume(0);
    holeSound.play();
    userHasTriggeredAudio = true;
  }
  
 // final screen button control:
 if (currentLevel == 10) {
   if (mouseXTr > 149 && mouseXTr < 368 && mouseYTr > 430 && mouseYTr < 464) {
     restart();
   }
   if (mouseXTr > 51 && mouseXTr < 468 && mouseYTr > 480 && mouseYTr < 516) {
     submitResult();
   }
 }
 
  // start screen: user click starts next level
  if (!levelRunning) {
    startNextLevel();
  }

  
  // for touch-controlled devices: empty mouse direction buffer when touch is released
  if (Modernizr.touch) {
    for (int i=0;i<mouseVecHistory.length;i++)
    {
      mouseVecHistory[i]= new PVector(0, 0);
    }
    pointerWasOutside = false;
  }
}

void mouseClicked() {
// restart button control:
 if (currentLevel != 10 && currentLevel != 0) {
   if (mouseXTr > 448 && mouseXTr < 472 && mouseYTr > 770 && mouseYTr < 794) {
     restart();
   }
 }
}


void startNextLevel() {
  levelRunning = true;
  inHole = false;
  currentLevel++;
  buildLevel();
}


void myCustomRenderer(World world) {
}

void keyPressed() {

  //keystroke impulse for desktop devices
  //left cursor
  if (keyCode == LEFT) {
    Vec2 impulse = new Vec2(-.01, 0);
    impulse = impulse.mul(sq(ballRadius));
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //right cursor
  if (keyCode == RIGHT) {
    Vec2 impulse = new Vec2(.01, 0);
    impulse = impulse.mul(sq(ballRadius));
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //up cursor
  if (keyCode == UP) {
    Vec2 impulse = new Vec2(0, -.01);
    impulse = impulse.mul(sq(ballRadius));
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //down cursor
  if (keyCode == DOWN) {
    Vec2 impulse = new Vec2(0, .01);
    impulse = impulse.mul(sq(ballRadius));
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  if (keyCode == 49) {
    currentLevel = 1;
    buildLevel();
  }
  if (keyCode == 50) {
    currentLevel = 2;
    buildLevel();
  }
  if (keyCode == 51) {
    currentLevel = 3;
    buildLevel();
  }
  if (keyCode == 52) {
    currentLevel = 4;
    buildLevel();
  }
  if (keyCode == 53) {
    currentLevel = 5;
    buildLevel();
  }
  if (keyCode == 54) {
    currentLevel = 6;
    buildLevel();
  }
  if (keyCode == 55) {
    currentLevel = 7;
    buildLevel();
  }
  if (keyCode == 56) {
    currentLevel = 8;
    buildLevel();
  }
  if (keyCode == 57) {
    currentLevel = 9;
    buildLevel();
  }
  if (key == 'a') {
    
    String[] params = {"s", counter, "v", serialize(gameData)};
    
    post_to_url("endgame.php", params, "post");
  }
  if (key == 'r') {
    restart();
  }
  if (key == 'm') {
    println (mouseXTr + ", " + mouseYTr + ", ");
  }
}

void submitResult() {
  String[] params = {"s", counter, "v", serialize(gameData)};
  
  post_to_url("endgame.php", params, "post");
}

void collision(Body b1, Body b2, float impulse)
{
   wallSounds[whichSoundLooper].cue(0);
   wallSounds[whichSoundLooper].volume(sqrt(impulse));
   wallSounds[whichSoundLooper].play();
   
   whichSoundLooper++;
   if (whichSoundLooper >= 5) whichSoundLooper = 0;
}

void resetBall() {
  for (var i = 0; i < balls.length; i++) {
    physics.getWorld().DestroyBody(balls[i]);
  }
  balls.length = 0;

  //create a new ball
  physics.setDensity(10.0);
  Body newBall = physics.createCircle(startingPoint.x, startingPoint.y, ballRadius);
  newBall.SetLinearDamping(1.2);
  balls = append(balls, newBall);
}

int[][] EckTeil = {{383,300,396,405,312,250},{312,250,396,405,136,351},{120,271,136,351,87,345},{136,351,396,405,87,345},{87,345,396,405,104,445},{262,500,104,445,396,405}};

int[][] pilatus = {{465,521,475,750,447,510},{447,510,475,750,434,495},{434,495,475,750,428,488},{428,488,475,750,423,488},{423,488,475,750,416,491},{416,491,475,750,394,477},{394,477,475,750,391,471},{391,471,475,750,384,473},{384,473,475,750,379,472},{379,472,475,750,365,478},{365,478,475,750,355,474},{355,474,475,750,348,466},{348,466,475,750,336,464},{336,464,475,750,319,446},{319,446,475,750,314,442},{314,442,475,750,306,432},{306,432,475,750,304,433},{304,433,475,750,300,432},{300,432,475,750,290,437},{290,437,475,750,286,441},{286,441,475,750,281,436},{281,436,475,750,276,432},{276,432,475,750,272,435},{266,425,272,435,257,433},{272,435,475,750,257,433},{257,433,475,750,252,440},{252,440,475,750,247,444},{247,444,475,750,244,444},{244,444,475,750,236,453},{236,453,475,750,231,448},{231,448,475,750,223,443},{223,443,475,750,215,443},{215,443,475,750,208,440},{208,440,475,750,200,442},{200,442,475,750,196,442},{196,442,475,750,193,444},{193,444,475,750,187,447},{187,447,475,750,182,445},{182,445,475,750,176,444},{176,444,475,750,168,445},{168,445,475,750,166,453},{166,453,475,750,161,455},{161,455,475,750,159,461},{159,461,475,750,153,467},{153,467,475,750,143,474},{143,474,475,750,130,479},{130,479,475,750,119,490},{119,490,475,750,113,493},{113,493,475,750,106,490},{110,628,106,490,249,631},{106,490,475,750,249,631},{249,631,475,750,249,679},{249,679,475,750,58,677},{53,747,58,677,475,750}};

int[][] star = {{266,280,331,352,248,370},{145,317,248,370,196,414},{248,370,331,352,196,414},{196,414,331,352,144,489},{144,489,331,352,228,506},{228,506,331,352,274,442},{274,442,331,352,289,502},{289,502,331,352,341,416},{377,343,341,416,331,352}};

int[][] wallBottomRight = {{239,751,219,748,241,212},{467,211,241,212,471,191},{471,191,241,212,220,191},{220,191,241,212,219,748}};

int[][] deflectorTopLeft = {{167,51,53,163,53,55}};

int[][] realPilatus = {{55,752,54,702,470,755},{470,755,54,702,468,661},{468,661,54,702,451,649},{451,649,54,702,425,636},{425,636,54,702,402,627},{380,614,402,627,372,618},{402,627,54,702,372,618},{372,618,54,702,349,616},{349,616,54,702,331,605},{331,605,54,702,309,608},{309,608,54,702,300,603},{300,603,54,702,297,604},{297,604,54,702,294,599},{294,599,54,702,290,599},{290,599,54,702,287,595},{287,595,54,702,281,591},{281,591,54,702,277,591},{277,591,54,702,272,590},{272,590,54,702,265,593},{261,592,265,593,258,593},{255,589,258,593,245,601},{258,593,265,593,245,601},{265,593,54,702,245,601},{245,601,54,702,244,597},{241,597,244,597,235,598},{235,598,244,597,230,604},{244,597,54,702,230,604},{230,604,54,702,229,602},{229,602,54,702,221,600},{211,597,221,600,209,603},{221,600,54,702,209,603},{198,604,209,603,198,607},{198,607,209,603,191,614},{209,603,54,702,191,614},{179,619,191,614,160,632},{191,614,54,702,160,632},{160,632,54,702,157,630},{157,630,54,702,150,629},{150,629,54,702,138,635},{130,639,138,635,125,645},{138,635,54,702,125,645},{112,649,125,645,105,653},{105,653,125,645,98,662},{125,645,54,702,98,662},{98,662,54,702,97,657},{97,657,54,702,90,656},{90,656,54,702,74,661},{56,667,74,661,54,702}};

int[][] pilatusTriangle = {{219,523,55,45,375,58}};

int[][] diagonalProtectors = {{277,224,324,177,285,232},{324,177,333,185,285,232},{277,96,285,88,324,143},{285,88,333,135,324,143},{187,135,235,88,196,143},{235,88,243,96,196,143},{187,185,196,177,235,232},{196,177,243,224,235,232}};

int[][] fiveShape = {{467,602,470,753,356,714},{470,753,49,749,356,714},{356,714,49,749,162,713},{162,713,49,749,49,602},{48,528,49,363,180,527},{181,559,180,527,211,592},{211,592,180,527,304,595},{304,595,180,527,335,564},{335,564,180,527,337,504},{337,504,180,527,307,473},{307,473,180,527,156,471},{156,471,180,527,49,363},{204,351,182,323,353,351},{470,468,353,351,469,221},{353,351,182,323,469,221},{184,223,469,221,182,323},{53,100,51,52,472,101},{470,53,472,101,51,52}};

int[][] zeroShape = {{475,596,475,749,360,712},{475,749,49,751,360,712},{360,712,49,751,166,711},{166,711,49,751,52,597},{186,255,215,222,187,563},{187,563,215,222,216,590},{216,590,215,222,310,590},{310,590,215,222,338,562},{338,562,215,222,339,252},{311,222,339,252,215,222},{58,210,51,53,169,101},{51,53,465,56,169,101},{169,101,465,56,363,101},{363,101,465,56,472,210}};

int[][] eichhoernchen = {{253,178,254,256,250,168},{250,168,254,256,243,157},{243,157,254,256,235,148},{235,148,254,256,222,139},{222,139,254,256,208,133},{208,133,254,256,194,130},{194,130,254,256,107,131},{107,143,107,131,118,145},{107,131,254,256,118,145},{118,145,254,256,119,365},{119,365,254,256,112,381},{112,381,254,256,107,399},{107,399,254,256,107,416},{107,416,254,256,110,428},{110,428,254,256,117,444},{117,444,254,256,125,451},{125,451,254,256,138,461},{138,461,254,256,158,468},{158,468,254,256,173,471},{403,469,173,471,403,456},{403,456,173,471,375,457},{173,471,254,256,375,457},{412,394,375,457,415,386},{415,386,375,457,416,379},{416,379,375,457,415,371},{415,371,375,457,410,363},{410,363,375,457,402,358},{402,358,375,457,395,356},{395,356,375,457,334,356},{375,457,254,256,334,356},{334,356,254,256,407,303},{405,267,407,303,368,267},{407,303,254,256,368,267},{368,267,254,256,368,263},{368,263,254,256,407,233},{407,233,254,256,405,200},{360,137,405,200,344,136},{344,136,405,200,359,158},{359,158,405,200,306,157},{306,136,306,157,294,136},{294,136,306,157,292,224},{306,157,405,200,292,224},{405,200,254,256,292,224},{273,237,292,224,254,256}};

int[][] alphorn = {{287,706,298,711,280,720},{298,711,311,708,280,720},{280,720,311,708,298,726},{311,708,346,682,298,726},{298,726,346,682,332,744},{346,682,394,633,332,744},{394,633,406,618,332,744},{332,744,406,618,431,742},{431,742,406,618,432,665},{432,665,406,618,437,663},{437,663,406,618,437,625},{437,625,406,618,432,615},{432,599,432,615,427,593},{427,593,432,615,414,597},{414,597,432,615,411,601},{411,601,432,615,414,610},{414,610,432,615,412,616},{412,616,432,615,406,618}};

int[][] edelweiss = {{94,670,96,661,102,674},{102,674,96,661,113,678},{118,685,113,678,129,687},{113,678,96,661,129,687},{129,687,96,661,133,681},{133,681,96,661,144,677},{144,677,96,661,155,664},{155,664,96,661,170,648},{170,648,96,661,168,642},{168,642,96,661,160,633},{160,633,96,661,144,627},{144,627,96,661,143,619},{143,619,96,661,147,614},{147,614,96,661,144,604},{144,604,96,661,134,603},{134,603,96,661,129,596},{129,596,96,661,123,602},{123,602,96,661,114,596},{114,596,96,661,108,603},{108,603,96,661,100,622},{100,622,96,661,86,632},{86,632,96,661,77,654},{88,661,77,654,96,661}};

int[][] jodler = {{155,351,140,356,150,318},{157,312,150,318,153,303},{150,318,140,356,153,303},{153,303,140,356,150,286},{154,278,150,286,150,268},{150,286,140,356,150,268},{150,268,140,356,144,258},{146,249,144,258,134,233},{144,258,140,356,134,233},{116,247,134,233,118,253},{118,253,134,233,128,258},{128,258,134,233,131,263},{134,233,140,356,131,263},{131,263,140,356,116,272},{116,272,140,356,109,265},{109,265,140,356,95,258},{96,242,93,248,91,238},{93,248,95,258,91,238},{91,238,95,258,80,241},{95,258,140,356,80,241},{78,249,80,241,84,259},{80,241,140,356,84,259},{84,259,140,356,56,270},{56,350,56,270,79,373},{79,373,56,270,93,367},{93,367,56,270,105,371},{105,371,56,270,110,369},{110,369,56,270,108,349},{56,270,140,356,108,349},{108,349,140,356,129,356},{129,356,140,356,127,373},{142,373,127,373,140,356}};

int[][] glocke = {{225,454,236,449,221,463},{221,463,236,449,222,474},{222,474,236,449,228,498},{228,498,236,449,250,506},{250,506,236,449,261,506},{261,506,236,449,278,500},{278,500,236,449,287,469},{236,449,220,430,287,469},{287,469,220,430,285,455},{285,455,220,430,274,447},{274,447,220,430,274,426},{274,426,220,430,268,413},{268,413,220,430,260,402},{260,402,220,430,242,400},{242,400,220,430,222,406},{214,413,222,406,220,430}};

int[][] kuh = {{148,56,172,77,149,72},{149,72,172,77,157,78},{157,78,172,77,148,88},{148,88,172,77,149,94},{149,94,172,77,136,105},{136,105,172,77,134,109},{134,109,172,77,139,117},{139,117,172,77,166,117},{166,117,172,77,179,131},{179,131,172,77,185,152},{185,152,172,77,191,157},{191,157,172,77,200,161},{193,195,201,188,220,198},{201,188,200,161,220,198},{200,161,172,77,220,198},{220,198,172,77,225,195},{225,195,172,77,223,176},{223,176,172,77,225,154},{225,154,172,77,253,153},{262,157,253,153,272,157},{272,157,253,153,283,152},{292,165,289,158,304,167},{289,158,283,152,304,167},{291,197,302,179,303,197},{302,179,304,167,303,197},{303,197,304,167,314,176},{319,195,314,176,327,195},{327,195,314,176,331,159},{314,176,304,167,331,159},{304,167,283,152,331,159},{331,159,283,152,329,132},{283,152,253,153,329,132},{329,132,253,153,331,105},{331,105,253,153,330,94},{330,94,253,153,319,87},{319,87,253,153,273,91},{273,91,253,153,231,92},{231,92,253,153,211,88},{211,88,253,153,186,90},{186,90,253,153,172,77}};

int[][] fahnenschwinger = {{398,364,417,365,390,370},{390,370,417,365,393,385},{393,385,417,365,390,389},{382,390,390,389,364,410},{364,410,390,389,364,426},{390,389,417,365,364,426},{364,426,417,365,378,445},{378,445,417,365,379,471},{379,471,417,365,387,518},{379,531,384,526,381,536},{384,526,387,518,381,536},{381,536,387,518,398,528},{387,518,417,365,398,528},{416,538,398,528,418,537},{418,537,398,528,413,527},{413,527,398,528,412,491},{398,528,417,365,412,491},{412,491,417,365,414,456},{414,456,417,365,417,408},{420,396,417,408,418,379},{417,408,417,365,418,379},{418,379,417,365,425,376},{417,365,338,255,425,376},{425,376,338,255,425,369},{425,369,338,255,412,350},{412,350,338,255,451,317},{451,317,338,255,463,316},{463,316,338,255,463,269},{463,269,338,255,447,253},{447,253,338,255,444,228},{444,228,338,255,402,225},{374,232,402,225,338,255}};



