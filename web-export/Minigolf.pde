
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

int howManyElements = 10;
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
  holeImg = loadImage("hole.png");
  startingPointImg = loadImage("starting-point.png");
  submitImg = loadImage("submit.png");
  restartImg = loadImage("restart.png");
  restartIconImg = loadImage("restart-icon.png");
  hillImg = loadImage("hill.jpg");
  
  mouseVecHistory = new PVector[5];
  for (int i=0;i<mouseVecHistory.length;i++)
  {
    mouseVecHistory[i]= new PVector(0, 0);
  }
  mouseVec = new PVector(0, 0);

  hole = new PVector(width/2, height/5);
  startingPoint = new PVector(width/2, height*.8);

  // sets up the collision callbacks
  // detector = new CollisionDetector (physics, this);


  //init the ball:
  physics.setDensity(10.0);
  balls = new Body[howManyElements];

  for (var i = 0; i < howManyElements; i++) {
    balls[i] = physics.createCircle(random(2, width-2), random(2, height-2), ballRadius);
    balls[i].SetLinearDamping(1.2);
  }


  // accelerometer
  accel = new Accelerometer();


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
}


void draw() {
  float widthRatio = width / getCanvasWidth();
  mouseXTr = widthRatio * mouseX;
  pmouseXTr = widthRatio * pmouseX;
  float heightRatio = height / getCanvasHeight();
  mouseYTr = heightRatio * mouseY;
  pmouseYTr = heightRatio * pmouseY;
    
  timeCounter++;
  
  // draw backgrounds
  noStroke();
  // draw startup dialog
  if (!userHasTriggeredAudio) {
    background(255);
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    fill(0);
    text("Klicken zum Starten", width/2, height/2);

  }
  // draw main background
  else {
    int alpha = 255;
    fill(0, alpha);
    image(groundImg, width/2, height/2);
    //background(207,116,108);
  }
  
  if (currentLevel == 10) {
    drawLevel();
  }

  // for mouse-controlled devices: calculate mouse direction with a buffer based on vectors (average of recent mouse motions)
  if ((mouseYTr != pmouseYTr || mouseXTr != pmouseXTr) && !Modernizr.touch) {
    mouseVecHistory = append(mouseVecHistory, new PVector(mouseYTr - pmouseYTr, mouseXTr - pmouseXTr));
    mouseVecHistory = reverse(shorten(reverse(mouseVecHistory)));
    mouseVec.set(0, 0);
    for (i = 0; i < mouseVecHistory.length; i++) {
      mouseVec.add(mouseVecHistory[i]);
    }
  }


  if (currentLevel != 0 && currentLevel != 10) {
    // draw hole and starting point
    image(holeImg, hole.x, hole.y);
    image(startingPointImg, startingPoint.x, startingPoint.y);

    drawLevel();
  }


  if (inHole) {
    // draw ball in hole
    noStroke();
    pushMatrix();
    translate(hole.x, hole.y);
    // Fancy ball graphics:

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
      if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * 1.5) {
        float force = sq(ballRadius) * .001 / (dist(ballPos.x, ballPos.y, hole.x, hole.y) / (holeRadius / 4));
        Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
        impulse.normalize();
        impulse = impulse.mul(force);
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
        
        drivebySound.volume(20);
        drivebySound.play();

      }
      else drivebySound.cue(0);


      // ball drops in hole
      if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * .7  && speed <= 2) {
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
    // Fancy ball graphics:

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
      fill(255);
      stroke(0);
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
  

  if (!levelRunning && currentLevel != 0 && currentLevel != 10) {
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    fill(0);
    text("Klicken für nächste Bahn", width/2+1, height/2+1);
    fill(255);
    text("Klicken für nächste Bahn", width/2, height/2);
  }


  if (currentLevel != 0 && currentLevel != 10) {
    // draw the hit counter
    fill(255);
    textSize(24);
    textAlign(RIGHT);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    text("Schläge: " + counter, width-20, 30);
  
    // draw the level indicator
    fill(255);
    textSize(24);
    textAlign(LEFT);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    text("Bahn " + currentLevel, 20, 30);
  }
}



void drawLevel() {
  
  
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
    drawPolygon(realPilatus);
    drawPolygon(pilatusTriangle);
  }
  
  if (currentLevel == 4) {
    fill(255);
    stroke(255);
    image(hillImg, width/2, 240);
    image(holeImg, hole.x, hole.y);
  }

  if (currentLevel == 5) {
    fill(255);
    stroke(255);
    drawPolygon(star);
  }
  
  if (currentLevel == 6) {
    fill(255);
    stroke(255);
    drawPolygon(wallBottomRight);
    drawPolygon(deflectorTopLeft);
  }
  if (currentLevel == 7) {
    fill(255);

    float[][] shape = {
      {
        100, 100, 300, 300, 100, 300
      }
      , {
        321, 251, 401, 248, 399, 375
      }
    };
    drawPolygon(shape);
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
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(100, 500);
    buildPolygonBody(realPilatus);
    buildPolygonBody(pilatusTriangle);
  }

  // Level 4 physics
  if (currentLevel == 4) {
    hole = new Vec2(width/2, 240);
    startingPoint = new Vec2(width/2, height * .8);
  }

  // Level 5 physics
  if (currentLevel == 5) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(100, 500);
    buildPolygonBody(star);
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
    for (int i=0;i<5;i++) {
      wallSounds[i].volume(0);
      wallSounds[i].play();
    }
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


  // to do: maybe display the labyrinth after completing
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

int[][] EckTeil = {
{
383, 300, 
396, 405, 
312, 250
}, 
{
312, 250, 
396, 405, 
136, 351
}, 
{
120, 271, 
136, 351, 
87, 345
}, 
{
136, 351, 
396, 405, 
87, 345
}, 
{
87, 345, 
396, 405, 
104, 445
}, 
{
262, 500, 
104, 445, 
396, 405
}};


int[][] pilatus = {{144,680,155,330,262,507},{262,718,155,330,432,452},{432,663,155,330,446,386},{423,542,446,386,393,295},{378,477,393,295,360,302},{393,506,446,386,360,302},{349,285,360,302,304,278},{360,302,446,386,304,278},{304,278,446,386,283,30},{283,301,446,386,265,331},{446,386,155,330,265,331},{244,308,265,331,203,301},{203,301,265,331,191,326},{191,326,265,331,155,330}};

int[][] star = 
{{
266, 280, 
331, 352, 
248, 370
}, 
{
145, 317, 
248, 370, 
196, 414
}, 
{
248, 370, 
331, 352, 
196, 414
}, 
{
196, 414, 
331, 352, 
144, 489
}, 
{
144, 489, 
331, 352, 
228, 506
}, 
{
228, 506, 
331, 352, 
274, 442
}, 
{
274, 442, 
331, 352, 
289, 502
}, 
{
289, 502, 
331, 352, 
341, 416
}, 
{
377, 343, 
341, 416, 
331, 352
}};

int[][] wallBottomRight =
{{
239, 751, 
219, 748, 
241, 212
}, 
{
467, 211, 
241, 212, 
471, 191
}, 
{
471, 191, 
241, 212, 
220, 191
}, 
{
220, 191, 
241, 212, 
219, 748
}};

int[][] deflectorTopLeft =
{{
51, 168, 
50, 52, 
68, 113
}, 
{
68, 113, 
50, 52, 
81, 92
}, 
{
81, 92, 
50, 52, 
97, 79
}, 
{
97, 79, 
50, 52, 
127, 68
}, 
{
50, 52, 
178, 50, 
127, 68
}, 
{
178, 60, 
127, 68, 
178, 50
}};

int[][] realPilatus = {{55,752,54,702,470,755},{470,755,54,702,468,661},{468,661,54,702,451,649},{451,649,54,702,425,636},{425,636,54,702,402,627},{380,614,402,627,372,618},{402,627,54,702,372,618},{372,618,54,702,349,616},{349,616,54,702,331,605},{331,605,54,702,309,608},{309,608,54,702,300,603},{300,603,54,702,297,604},{297,604,54,702,294,599},{294,599,54,702,290,599},{290,599,54,702,287,595},{287,595,54,702,281,591},{281,591,54,702,277,591},{277,591,54,702,272,590},{272,590,54,702,265,593},{261,592,265,593,258,593},{255,589,258,593,245,601},{258,593,265,593,245,601},{265,593,54,702,245,601},{245,601,54,702,244,597},{241,597,244,597,235,598},{235,598,244,597,230,604},{244,597,54,702,230,604},{230,604,54,702,229,602},{229,602,54,702,221,600},{211,597,221,600,209,603},{221,600,54,702,209,603},{198,604,209,603,198,607},{198,607,209,603,191,614},{209,603,54,702,191,614},{179,619,191,614,160,632},{191,614,54,702,160,632},{160,632,54,702,157,630},{157,630,54,702,150,629},{150,629,54,702,138,635},{130,639,138,635,125,645},{138,635,54,702,125,645},{112,649,125,645,105,653},{105,653,125,645,98,662},{125,645,54,702,98,662},{98,662,54,702,97,657},{97,657,54,702,90,656},{90,656,54,702,74,661},{56,667,74,661,54,702}};

int[][] pilatusTriangle = {{219, 523, 55, 45,375, 58}};

int[][] diagonalProtectors = {{277,224,324,177,285,232},{324,177,333,185,285,232},{277,96,285,88,324,143},{285,88,333,135,324,143},{187,135,235,88,196,143},{235,88,243,96,196,143},{187,185,196,177,235,232},{196,177,243,224,235,232}};

int[][] fiveShape = {{474,47,466,57,53,50},{468,117,470,748,413,117},{413,117,470,748,413,161},{149,161,413,161,151,322},{151,322,413,161,179,307},{179,307,413,161,233,293},{233,293,413,161,292,291},{292,291,413,161,331,298},{331,298,413,161,385,341},{385,341,413,161,423,402},{423,402,413,161,431,456},{413,161,470,748,431,456},{431,456,470,748,422,514},{422,514,470,748,395,565},{395,565,470,748,356,614},{356,614,470,748,302,639},{470,748,54,747,302,639},{302,639,54,747,236,638},{236,638,54,747,159,603},{159,603,54,747,102,559},{54,747,53,50,102,559},{158,542,143,523,182,561},{182,561,143,523,212,576},{212,576,143,523,254,589},{254,589,143,523,310,585},{310,585,143,523,345,559},{345,559,143,523,370,521},{370,521,143,523,379,480},{379,480,143,523,378,431},{378,431,143,523,357,383},{357,383,143,523,316,355},{143,523,102,559,316,355},{316,355,102,559,257,350},{257,350,102,559,200,356},{200,356,102,559,152,390},{152,390,102,559,143,400},{143,400,102,559,101,399},{102,559,53,50,101,399},{101,399,53,50,102,114},{53,50,466,57,102,114},{413,115,102,114,466,57},{410,111,464,50,417,118},{467,118,417,118,464,50}};

int[][] zeroShape = {{263,643,265,748,198,640},{198,640,265,748,142,609},{267,641,324,632,273,742},{324,632,375,593,273,742},{273,742,375,593,465,746},{375,593,414,529,465,746},{414,529,424,454,465,746},{424,454,426,375,465,746},{426,375,428,272,465,746},{465,746,428,272,468,52},{428,272,423,239,468,52},{423,239,404,202,468,52},{404,202,367,157,468,52},{367,157,321,128,468,52},{321,128,273,124,468,52},{273,124,187,129,468,52},{468,52,187,129,55,53},{187,129,136,152,55,53},{136,152,106,195,55,53},{106,195,92,247,55,53},{92,247,92,341,55,53},{92,341,96,491,55,53},{55,53,96,491,51,750},{96,491,111,572,51,750},{111,572,142,609,51,750},{51,750,142,609,265,748},{289,587,262,590,313,580},{313,580,262,590,336,565},{336,565,262,590,352,554},{352,554,262,590,366,534},{366,534,262,590,375,509},{375,509,262,590,377,491},{377,491,262,590,378,269},{378,269,262,590,372,234},{372,234,262,590,360,207},{360,207,262,590,336,181},{336,181,262,590,316,171},{316,171,262,590,259,164},{259,164,262,590,223,166},{223,166,262,590,193,171},{193,171,262,590,167,191},{167,191,262,590,155,209},{155,209,262,590,149,251},{149,251,262,590,152,495},{152,495,262,590,158,542},{158,542,262,590,182,572},{220,586,182,572,262,590},{258,644,271,644,280,742},{258,644,280,742,250,743}};

