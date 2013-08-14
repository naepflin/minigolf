
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

int howManyElements = 20;
int whichSoundLooper = 0;
float ballRadius = 5;

Physics physics; // The physics handler: we'll see more of this later
// rigid bodies for the droid and two crates

Body[] block = new Body[0];

Body[] balls;



float[] angles;
float mousedir = 0;

PVector [] mouseVecHistory;
PVector mouseVec;

PVector hole;

int counter = 0;

int[][] blockShapes;


// a handler that will detect collisions
CollisionDetector detector; 




// this is used to remember that the user 
// has triggered the audio on iOS... see mousePressed below
boolean userHasTriggeredAudio = false;



// define levels
  
boolean levelRunning = false;

int currentLevel = 0;

//"hole in one" level
String level1 = "XXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXX       XXX X XXXXXXXXXXXXXXXXXX\nXXXXXX XXXXX XXX X XXXXXXXXXXXXXXXXXX\nXXXXXX XXXXX     X X           XXXXXX\nXXXXXX XXXXXXXXXXX XXXXXXXX XXXXXXXXX\nXXXXXX XXXXXXXXXXX XXXXXXXX XXXXXXXX\nXXX              X X   XXXX XXXXXXX\nXXX XXXX XXXXXXXXX XXXXXXXX    XXXXX\nXXX   XX XXXXXXXXX XX  XXXXXXX XXXXXX\nXXXXX XX         X XX         XXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX";

//"smiley" level
String level2 = "XXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\n                                     \n                                     \n                                     \n                                     \n                                     \n             X         X             \n                                     \n                                     \n                                     \n                                     \n           XX           XX           \n            XX         XX            \n             XXXXXXXXXXX             \n                                     \n                                     \n                                     ";

//"labyrinth one" level
String level3 = "XXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\n                                     \n                                     \n                                     \n                                     \n                                     \n     XXXXXXXXX         XXXXXXXXXXXXXX\n     X       X         X             \n     X       X         X             \n     X       X         X             \n     X       X         X             \n     X       X         X             \n     X       X         X             \n     X       XXXXXXXXXXX             \n                                     \n                                     \nXXXXXXXXXXXXX                        ";

//"labyrinth two" level
String level4 = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   \n        X                            \n        X                            \n        X   XXXXXXXXXXXXXXXXXXXXXXXXX\n                                     \n                                     \n     XXXXXXXXX    X    XXXXXXXXXXXXXX\n     X       X    X    X             \n     X       X    X    X             \n     X       X    X                 \n     X       X    X    X             \n     X       X    X    X             \n     X       X    X    X             \n     X       XXXXXXXXXXX             \n             X                       \n             X                       \nXXXXXXXXXXXXXX                       ";

//"labyrinth three" level
String level5 = "XXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX\nXXXXXX       XXX   XXXXXXXXXXXXXXXXXX\nXXXXXX XXXXX XXX X XXXXXXXXXXXXXXXXXX\nXXXXXX XXXXX     X             XXXXXX\nXXXXXX XXXXXXXXXXXXXXXXXXXX XXXXXXXXX\nXXXXXX XXXXXXXXXXX XXXXXXXX XXXXXXXX\nXXX                    XXXX XXXXXXX\nXXX XXXX XXXXXXXXX XXXXXXXX    XXXXX\nXXX   XX XXXXXXXXX XX  XXXXXXX XXXXXX\nXXXXX XX         X XX         XXXXXX\nXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXXXXX";

String[] levels = {level1, level2, level3, level4, level5};





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
  // check that the level is still OK 
  if (currentLevel >= levels.length)
  {
      println("dasde");

    currentLevel = 0;
  }
  
  String labyrinthString = levels[currentLevel];
  Array labyrinthArray = split(labyrinthString, "\n");

  var yResolution = labyrinthArray.length; // how many rows does the labyrinth have?

  var xResolution = 0;
  for (i = 0; i < yResolution; i++) { // how many columns does the labyrinth have?
    if (labyrinthArray[i].length > xResolution) {
      xResolution = labyrinthArray[i].length;
    }
  }


  for (i = 0; i < yResolution; i++) {
    for (j = 0; j < xResolution; j++) {
      if (labyrinthArray[i].charAt(j) == "X") {
        var topleftX = j * width / xResolution;
        var topleftY = height/8 + i * height *6/8 / yResolution;
        var bottomrightX = (j+1) * width / xResolution;
        var bottomrightY = height/8 + (i+1) * height *6/8 / yResolution;
        block = append(block, physics.createRect(topleftX-1, topleftY-1, bottomrightX+1, bottomrightY+1));
        
        
        // saving block in blockShapes (STILL BUGGY)
        int[] thisBlock = {topleftX, topleftY, bottomrightX, bottomrightY};
        blockShapes = append(blockShapes, thisBlock);
        println("hehe");
        println(blockShapes);
      }
    }
  }

}



void draw() {
  // draw backgrounds
  noStroke();
  if (!userHasTriggeredAudio) {
    // draw startup dialog
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
  else {
    // draw main background
    int alpha = 255;
    fill(0, alpha);
    background(207,116,108);
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
  fill(0);
  ellipse(0, 0, ballRadius*5, ballRadius*5);
  popMatrix();

  // ball-specific code:
  for (i = 0; i < balls.length; i++) {
    Vec2 ballPos = physics.worldToScreen(balls[i].getWorldCenter());
    float speed = sqrt(abs((balls[i].getLinearVelocity().x) + sq(balls[i].getLinearVelocity().y)));

    if (mouseY - pmouseY != 0 || mouseX - pmouseX != 0) {
      /*checkIfTouched(ballPos.x, ballPos.y);*/
    }

    // gravity when close to the hole
    if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= ballRadius * 6) {
      float force = sq(ballRadius) * .001 / (dist(ballPos.x, ballPos.y, hole.x, hole.y) / ballRadius);
      Vec2 impulse =  new Vec2((hole.x-ballPos.x), (hole.y-ballPos.y));
      impulse.normalize();
      impulse = impulse.mul(force);
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }

    if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= ballRadius * 2  && speed <= 1.5) {
      //println("Won  " + speed);
      physics.getWorld().DestroyBody(balls[i]);
      balls = concat(subset(balls,0,i), subset(balls,i+1,balls.length));
    }
    

    if (dist(mouseX, mouseY, ballPos.x, ballPos.y) <= 30 && speed <= .075 * ballRadius)
    {
      Vec2 impulse = new Vec2(mouseVec.y*.0002*sq(ballRadius), mouseVec.x*.0002*sq(ballRadius));
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
      counter++;
    }

    // draw balls
    pushMatrix();
    translate(ballPos.x, ballPos.y);
    // Fancy ball graphics:

    // (shadow)
    pushMatrix();
    fill(0,50);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.2, ballRadius*2.2);
    popMatrix();
    
    // (main)
    fill(230);
    ellipse(0, 0, ballRadius*2, ballRadius*2);

    // (reflection)
    translate(-ballRadius/2, -ballRadius/2);
    fill(255);
    ellipse(0, 0, ballRadius/3, ballRadius/2);
     
    popMatrix();
  }
  
  fill(255);
  textSize(32);
  textAlign(RIGHT);
  PFont mono;
  mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
  textFont(mono);
  text(counter, width-20, 40);
  
  for (i = 0; i < block.length; i++) {
    rect(); 
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

  // to do: maybe display the labyrinth after completing

  buildLevel();
  resetBallPosition();

  currentLevel++;
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
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //right cursor
  if (keyCode == RIGHT) {
    Vec2 impulse = new Vec2(.01, 0);
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //up cursor
  if (keyCode == UP) {
    Vec2 impulse = new Vec2(0, -.01);
    for (var i = 0; i < balls.length; i++) {
      balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
    }
  }
  //down cursor
  if (keyCode == DOWN) {
    Vec2 impulse = new Vec2(0, .01);
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

}


