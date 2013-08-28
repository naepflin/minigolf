
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
PImage ground5Img;
PImage bahnImg;
PImage gleisImg;

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
  ground5Img = loadImage("platz-k5.jpg");
  holeImg = loadImage("hole.png");
  startingPointImg = loadImage("starting-point.png");
  submitImg = loadImage("submit.png");
  restartImg = loadImage("restart.png");
  restartIconImg = loadImage("restart-icon.png");
  hillImg = loadImage("hill.jpg");
  bahnImg = loadImage("bahn.png");
  gleisImg = loadImage("gleis.png");
  
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
  if (currentLevel == 5) image(ground5Img, width/2, height/2);
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
      
      if (currentLevel == 4 && dist(ballPos.x, ballPos.y, hole.x, hole.y) > 52 && dist(ballPos.x, ballPos.y, hole.x, hole.y) < 145) {
        float force = 0.03;
        Vec2 impulse =  new Vec2(-(hole.x-ballPos.x), -(hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      if (currentLevel == 4 && dist(ballPos.x, ballPos.y, hole.x, hole.y) <= 52 && dist(ballPos.x, ballPos.y, hole.x, hole.y) > holeRadius * 1.5) {
        float force = 0.06;
        Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      
      if (currentLevel == 5 && dist(ballPos.x, ballPos.y, 50, 273) < 145) {
        float force = 0.03;
        Vec2 impulse =  new Vec2(1, -.5);
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      }
      if (currentLevel == 5 && dist(ballPos.x, ballPos.y, 474, 465) < 145) {
        float force = 0.07;
        Vec2 impulse =  new Vec2(-1, -0.2);
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
      rect(-5, -15, 10, 30);
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
  
  
  
  
  if (currentLevel == 2) {
    fill(255);
    stroke(255);
    drawPolygon(diagonalProtectors);
  }

  if (currentLevel == 3) {
    fill(255);
    stroke(255);
    drawPolygon(pilatus);
  }
  
  if (currentLevel == 4) {
    fill(255);
    stroke(255);
    image(hillImg, hole.x, hole.y);
    image(holeImg, hole.x, hole.y);
  }

  if (currentLevel == 5) {
    fill(255);
    stroke(255);
    drawPolygon(sRechteBande);
    drawPolygon(sLinkeBande);
  }
  
  if (currentLevel == 6) {
    fill(255);
    stroke(255);
    drawPolygon(wallBottomRight);
    drawPolygon(deflectorTopLeft);
  }
  if (currentLevel == 7) {
    fill(255);
    imageMode(CORNER);
    image(gleisImg,20,500);
    float bahnPosX = timeCounter%400;
    if (timeCounter%400 > 200) bahnPosX = 400 - timeCounter%400;
    float bahnPosY = 480-timeCounter%400/200*50;
    if (timeCounter%400 > 200) bahnPosY = 480-(100-timeCounter%400/200*50);
    image(bahnImg,bahnPosX,bahnPosY);
    imageMode(CENTER);
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
  
  // Level 1 physics
  if (currentLevel == 1) {
    hole = new Vec2(width/2, height*.2);
    startingPoint = new Vec2(width/2, height*.8);
  }
  // Level 2 physics
  if (currentLevel == 2) {
    hole = new Vec2(width/2, height*.2);
    startingPoint = new Vec2(width/2, height*.8);
    buildPolygonBody(diagonalProtectors);
  }
  
  
  // Level 3 physics
  if (currentLevel == 3) {
    hole = new Vec2(254, 508);
    startingPoint = new Vec2(158, 150);
    buildPolygonBody(pilatus);
  }

  // Level 4 physics
  if (currentLevel == 4) {
    hole = new Vec2(width/2, 350);
    startingPoint = new Vec2(width/2, height * .8);
  }

  // Level 5 physics
  if (currentLevel == 5) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(155, 652);
    buildPolygonBody(sLinkeBande);
    buildPolygonBody(sRechteBande);
  }
  
  // Level 6 physics
  if (currentLevel == 6) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(134, 671);
    buildPolygonBody(wallBottomRight);
    buildPolygonBody(deflectorTopLeft);
  }

  // Level 7 physics
  if (currentLevel == 7) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(100, 500);

    float[][] polygons = {
      {
        100, 100, 300, 300, 100, 300
      }
      , {
        321, 251, 401, 248, 399, 375
      }
    };
    buildPolygonBody(polygons);
  }

  // Level 8 physics
  if (currentLevel == 8) {
    hole = new Vec2(340, 138);
    startingPoint = new Vec2(144, 561);
    buildPolygonBody(fiveShape);
  }
  // Level 9 physics
  if (currentLevel == 9) {
    hole = new Vec2(263, 615);
    startingPoint = new Vec2(251, 145);
    buildPolygonBody(zeroShape);
  }

  resetBall();  
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
  
  
  //println (mouseXTr + ", " + mouseYTr + ", ");
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

