
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
AudioPlayer[] crateSounds;

int howManyElements = 1;
int whichSoundLooper = 0;
float ballRadius = 10;
float holeRadius = 20;

Physics physics; // The physics handler: we'll see more of this later
// rigid bodies for the droid and two crates

Body[] block = new Body[0];

Body[] balls;

PImage groundImg;
PImage holeImg;
PImage startingPointImg;

float[] angles;
float mousedir = 0;

PVector [] mouseVecHistory;
PVector mouseVec;

PVector hole;

int counter = 0;

Boolean inHole = false;


// a handler that will detect collisions
CollisionDetector detector; 




// this is used to remember that the user 
// has triggered the audio on iOS... see mousePressed below
boolean userHasTriggeredAudio = false;



// define levels
  
boolean levelRunning = false;

int currentLevel = 0;



void setup() {
  size(520, 800);
  //size(520, 500);
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

  angles = new float[10];
  for (int i=0;i<angles.length;i++)
  {
    angles[i]=0;
  }
  mouseVecHistory = new PVector[10];
  for (int i=0;i<mouseVecHistory.length;i++)
  {
    mouseVecHistory[i]= new PVector(1, 1);
  }
  mouseVec = new PVector(1, 1);

  hole = new PVector(width/2, height/5);

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
  // now an array of crate sounds
  crateSounds = new AudioPlayer[howManyElements];
  for (int i=0;i<howManyElements;i++) {
    crateSounds[i] = maxim.loadFile("crate2.wav");
    crateSounds[i].setLooping(false);
  }

  // collision callbacks
  detector = new CollisionDetector (physics, this);
}

void buildLevel() {
  
  // set density to 0 i.e. fixed physical element
  physics.setDensity(0);
  // delete the block objects from the world
  for (i = 0; i < block.length; i++) {
    physics.getWorld().DestroyBody(block[i]);
  }
  // empty the block array
  block.length = 0;



  // build the new level
  // reset if last level is reached 
  if (currentLevel >= 10)
  {
    currentLevel = 0;
  }
  
  
  physics.createRect(40, 40, 60, height-40);
  physics.createPolygon(100,100,300,300,100,300);
  
  // Level 1 physics
  if (currentLevel == 1) {
        block = append(block, physics.createRect(40, 40, 60, height-40));
        block = append(block, physics.createRect(40, 40, width-40, 60));
        block = append(block, physics.createRect(width-60, 40, width-40, height-40));
        block = append(block, physics.createRect(40, height-60, width-40, height-40));
  }
  // Level 2 physics
  if (currentLevel == 1) {
        block = append(block, physics.createRect(40, 40, 60, height-40));
        block = append(block, physics.createRect(40, 40, width-40, 60));
        block = append(block, physics.createRect(width-60, 40, width-40, height-40));
        block = append(block, physics.createRect(40, height-60, width-40, height-40));
  }

 
}



void draw() {
  // draw backgrounds
  noStroke();
  // draw startup dialog
  if (!userHasTriggeredAudio) {
    fill(0, 0, 120);
    rect(0, 0, width, height);
    fill(255);
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    text("Tap to start", width/2, height/2);
  }
  // draw main background
  else {
    int alpha = 255;
    fill(0, alpha);
    image(groundImg,width/2,height/2);
    //background(207,116,108);
    
  }
  
  if (!levelRunning) {
    fill(255);
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    text("Tap for next level", width/2, height/2);
  }

  // calculate mouse direction with a buffer based on vectors (average of recent mouse motions)
  if (mouseY - pmouseY != 0 || mouseX - pmouseX != 0) {
    mouseVecHistory = append(mouseVecHistory, new PVector(mouseY - pmouseY, mouseX - pmouseX));
    mouseVecHistory = reverse(shorten(reverse(mouseVecHistory)));
    mouseVec.set(0, 0);
    for (i = 0; i < mouseVecHistory.length; i++) {
      mouseVec.add(mouseVecHistory[i]);
    }
  }


  // draw helper line to visualize mouse direction (debug)
  /*pushMatrix();
  translate(width/2, height/2);
  stroke(0, 255, 0);
  line(0, 0, mouseVec.y, mouseVec.x);
  popMatrix(); 
  noStroke();*/

  // draw hole
  pushMatrix();
  translate(hole.x, hole.y);
  //fill(0);
  //ellipse(0, 0, ballRadius*5, ballRadius*5);
  image(holeImg,0,0);
  popMatrix();
  image(startingPointImg, width/2, height*.75);


  if(inHole) {
    // draw balls
    pushMatrix();
    translate(hole.x, hole.y);
    // Fancy ball graphics:

    // (shadow)
    pushMatrix();
    fill(0,70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.6, ballRadius*2.6);
    popMatrix();
    
    // (main)
    fill(30);
    ellipse(0, 0, ballRadius*2, ballRadius*2);

    // (reflection)
    translate(-ballRadius/2, -ballRadius/2);
    fill(60);
    ellipse(0, 0, ballRadius/3, ballRadius/2);
     
    popMatrix();
  }
      



  // ball-specific code:
  for (i = 0; i < balls.length; i++) {
    Vec2 ballPos = physics.worldToScreen(balls[i].getWorldCenter());
    float speed = sqrt(abs((balls[i].getLinearVelocity().x) + sq(balls[i].getLinearVelocity().y)));

    if (mouseY - pmouseY != 0 || mouseX - pmouseX != 0) {
      /*checkIfTouched(ballPos.x, ballPos.y);*/
    }

    // gravity when close to the hole
    if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * 1.5) {
      float force = sq(ballRadius) * .001 / (dist(ballPos.x, ballPos.y, hole.x, hole.y) / (holeRadius / 4));
      Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
      impulse.normalize();
      impulse = impulse.mul(force);
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }


    if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * .7  && speed <= 1.5) {
      //println("Won  " + speed);
      physics.getWorld().DestroyBody(balls[i]);
      balls = concat(subset(balls,0,i), subset(balls,i+1,balls.length));
      inHole = true;
      levelRunning = false;
    }
      
        
    // draw balls
    pushMatrix();
    translate(ballPos.x, ballPos.y);
    // Fancy ball graphics:

    // (shadow)
    pushMatrix();
    fill(0,70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.6, ballRadius*2.6);
    popMatrix();
    
    // (main)
    fill(230);
    ellipse(0, 0, ballRadius*2, ballRadius*2);

    // (reflection)
    translate(-ballRadius/2, -ballRadius/2);
    fill(255);
    ellipse(0, 0, ballRadius/3, ballRadius/2);
     
    popMatrix();
    

    // apply and count hit
    if (dist(mouseX, mouseY, ballPos.x, ballPos.y) <= 30 && speed <= .075 * ballRadius)
    {
      Vec2 impulse = new Vec2(mouseVec.y*.0002*sq(ballRadius), mouseVec.x*.0002*sq(ballRadius));
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      counter++;
    }

  }
  
  drawLevel();

  
  // draw the hit counter
  fill(255);
  textSize(32);
  textAlign(RIGHT);
  PFont mono;
  mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
  textFont(mono);
  text(counter, width-20, 40);

  // draw the level indicator
  fill(255);
  textSize(32);
  textAlign(LEFT);
  PFont mono;
  mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
  textFont(mono);
  text("Bahn " + currentLevel, 20, 40);
  
  
  for (i = 0; i < block.length; i++) {
    rect(); 
  }
  
}

void drawLevel() {
  if (currentLevel == 1) {
    fill(255);
    rect(40,40,width-80, 20); //horizontal bar
    rect(40,40,20,height-80); //vertical bar
    rect(40,height-60,width-80, 20); //horizontal bar
    rect(width-60,40,20,height-80); //vertical bar
  }
}


// on iOS, the first audio playback has to be triggered directly by a user interaction
void mouseReleased() {
  if (!userHasTriggeredAudio) {
    /*for (int i=0;i<howManyElements;i++) {
      crateSounds[i].volume(0);
      crateSounds[i].play();
    }*/
    userHasTriggeredAudio = true;
    buildLevel();
    resetBallPosition();
  }
  if (!levelRunning) {
    startNextLevel();
  }
}

/*Boolean checkIfTouched(float pointX, float pointY) {
 PVector a = new PVector(pmouseX, pmouseY);
 PVector b = new PVector(mouseX, mouseY);
 PVector n = PVector.sub(b, a);
 PVector p = new PVector(pointX, pointY);
 
 PVector pointToLine = PVector.sub(PVector.sub(a, p), PVector.mult(n, PVector.dot(PVector.sub(a,p), n)));
 float distance = pointToLine.mag();
 stroke(0,0,0,20);
 fill(0,0);
 line(pmouseX, pmouseY, mouseX, mouseY);
 ellipse(pmouseX, pmouseY, 20, 20);
 
 if (distance <= 10 || dist(pmouseX, pmouseY, pointX, pointY) <= 10) {
 
 println("hit " + round(distance) + " X: " + pointX + " Y: " + pointY);
 pushMatrix();
 translate(pointX, pointY);
 
 // flash to show ball was hit
 
 fill(255,0,0);
 ellipse(0, 0, 40, 40);
 popMatrix();
 
 stroke(255,0,0);
 line(a.x, a.y, b.x, b.y);
 
 }
 }*/

void startNextLevel() {
  levelRunning = true;
  inHole = false;
  currentLevel++;

  // to do: maybe display the labyrinth after completing
  buildLevel();
  resetBallPosition();

}


void myCustomRenderer(World world) {
  // Accelerometer visualization
  //stroke(0);
  //strokeWeight(1);
  //line(width/2, height/2, width/2 + 20 * accel.getX(), height/2 - 20 * accel.getY());
  //println(frameRate);

  // Accelerometer impulse
  /* Vec2 impulse = new Vec2(.001*accel.getX(), -.001*accel.getY());
   for (var i = 0; i < balls.length; i++) {
   balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
   }*/
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
}


void collision(Body b1, Body b2, float impulse)
{
  crateSounds[whichSoundLooper].cue(0);
  //crateSounds[whichSoundLooper].speed(0.25 + (impulse / 250));// 10000 as the crates move slower??
  crateSounds[whichSoundLooper].volume(impulse);
  crateSounds[whichSoundLooper].play();

  whichSoundLooper++;
  if (whichSoundLooper >= howManyElements) {
    whichSoundLooper = 0;
  }
}

void resetBallPosition() {
    for (var i = 0; i < balls.length; i++) {
      Vec2 position = new Vec2(width/2, height*.75);
      position = physics.screenToWorld(position);
      balls[i].setPosition(position);

      Vec2 velocity = new Vec2(0, 0);
      balls[i].setLinearVelocity(velocity);
    }
}


