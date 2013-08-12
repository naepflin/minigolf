
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


Physics physics; // The physics handler: we'll see more of this later
// rigid bodies for the droid and two crates

Body[] block = new Body[0];

Body[] sand;



float[] angles;
float mousedir = 0;

PVector [] mouseVecHistory;
PVector mouseVec;


// a handler that will detect collisions
CollisionDetector detector; 




// this is used to remember that the user 
// has triggered the audio on iOS... see mousePressed below
boolean userHasTriggeredAudio = false;


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
    mouseVecHistory[i]= new PVector(1,1);
  }
  mouseVec = new PVector(1,1);


  // sets up the collision callbacks
  // detector = new CollisionDetector (physics, this);

  //init the particles:  
  physics.setDensity(10.0);
  sand = new Body[howManyElements];

  for (var i = 0; i < howManyElements; i++) {
    sand[i] = physics.createCircle(random(2, width-2), random(2, height-2), 2);
    sand[i].SetLinearDamping(.2);
  }



  accel = new Accelerometer();


// init sounds
  maxim = new Maxim(this);
  // now an array of crate sounds
  crateSounds = new AudioPlayer[howManyElements];
  for (int i=0;i<howManyElements;i++) {
    crateSounds[i] = maxim.loadFile("crate2.wav");
    crateSounds[i].setLooping(false);
  }

  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);
}

void buildLabyrinth() {
  physics.setDensity(0);

  // delete the block objects from the world
  for (i = 0; i < block.length; i++) {
    physics.getWorld().DestroyBody(block[i]);
  }

  // empty the block array
  block.length = 0;
}



void draw() {
  noStroke();

  if (!userHasTriggeredAudio) {
    //start dialog
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
    //labyrinth area
    var alpha = 255;
    fill(0, alpha);
    background(40);
  }



   
  //mouse direction calculation with buffer: Take average of previous angles
  if(mouseY - pmouseY != 0 || mouseX - pmouseX != 0) {
    mousedir = 0;
    angles[angles.length-1] = atan2(mouseY - pmouseY,mouseX - pmouseX);    
    for (int i=0;i<(angles.length-1);i++)
    {
      angles[i] = angles[i+1];
      mousedir += angles[i];
    }
    mousedir = (mousedir + angles[angles.length-1]) / angles.length;

    
    //mouse direction calculation with buffer based on vectors
    mouseVecHistory = append(mouseVecHistory, new PVector(mouseY - pmouseY,mouseX - pmouseX));
    mouseVecHistory = reverse(shorten(reverse(mouseVecHistory)));

    mouseVec.set(0, 0);
    for (i = 0; i < mouseVecHistory.length; i++) {
      mouseVec.add(mouseVecHistory[i]);
    }
    

  }
  
  pushMatrix();
  translate(mouseX, mouseY);
  rotate(mousedir);
  fill(255,0,0);
  rect(-2.5, -10, 5, 20);
  popMatrix();


 
  pushMatrix();
  translate(width/2, height/2);
  rotate(mousedir);
  stroke(255,0,0);
  line(0,0,100,0);
  popMatrix();

  PVector stdvec = PVector.normalize(mouseVec);
  
  pushMatrix();
  translate(width/2, height/2);
  stroke(0,255,0);
  line(0,0,stdvec.y*100,stdvec.x*100);
  popMatrix(); 
  
  pushMatrix();
  translate(mouseX, mouseY);
  rotate(atan(stdvec.x/stdvec.y));
  fill(0,255,0);
  rect(-2.5, -10, 5, 20);
  popMatrix();


}

// on iOS, the first audio playback has to be triggered directly by a user interaction
void mouseReleased() {
  if (!userHasTriggeredAudio) {
    for (int i=0;i<howManyElements;i++) {
      crateSounds[i].volume(0);
      crateSounds[i].play();
    }
    userHasTriggeredAudio = true;
    buildLabyrinth();
    resetSandPosition();
  }
  if (!levelRunning) {
    startNextLevel();
  }
}


void startNextLevel() {
  levelRunning = true;

  // to do: maybe display the labyrinth after completing

  buildLabyrinth();
  resetSandPosition();

  currentLevel++;
}


void myCustomRenderer(World world) {
  // Accelerometer visualization
  //stroke(0);
  //strokeWeight(1);
  //line(width/2, height/2, width/2 + 20 * accel.getX(), height/2 - 20 * accel.getY());
  //println(frameRate);
  // Accelerometer impulse
  Vec2 impulse = new Vec2(.001*accel.getX(), -.001*accel.getY());
  for (var i = 0; i < sand.length; i++) {
    sand[i].applyImpulse(impulse, sand[i].getWorldCenter());
  }


  noStroke();
  fill(255);
  for (int i = 0; i < sand.length; i++)
  {
    Vec2 worldCenter = sand[i].getWorldCenter();
    Vec2 sandPos = physics.worldToScreen(worldCenter);
    pushMatrix();
    translate(sandPos.x, sandPos.y);

    // Minimalist ball graphics:
    fill(255);
    ellipse(0, 0, 4, 4);

    /* Fancy ball graphics version:
     translate(3,3);
     fill(255, 10);
     ellipse(0, 0, 6, 6);
     translate(-3,-3);
     fill(50);
     ellipse(0, 0, 4, 4);
     translate(-1, -1);
     fill(255);
     ellipse(0, 0, 1.5, 2);
     */



    popMatrix();
  }


}

void keyPressed() {

  //keystroke impulse for desktop devices
  //left cursor
  if (keyCode == LEFT) {
    Vec2 impulse = new Vec2(-.01, 0);
    for (var i = 0; i < sand.length; i++) {
      sand[i].applyImpulse(impulse, sand[i].getWorldCenter());
    }
  }
  //right cursor
  if (keyCode == RIGHT) {
    Vec2 impulse = new Vec2(.01, 0);
    for (var i = 0; i < sand.length; i++) {
      sand[i].applyImpulse(impulse, sand[i].getWorldCenter());
    }
  }
  //up cursor
  if (keyCode == UP) {
    Vec2 impulse = new Vec2(0, -.01);
    for (var i = 0; i < sand.length; i++) {
      sand[i].applyImpulse(impulse, sand[i].getWorldCenter());
    }
  }
  //down cursor
  if (keyCode == DOWN) {
    Vec2 impulse = new Vec2(0, .01);
    for (var i = 0; i < sand.length; i++) {
      sand[i].applyImpulse(impulse, sand[i].getWorldCenter());
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

void resetSandPosition() {
  for (var i = 0; i < howManyElements; i++) {
    Vec2 newPosition = new Vec2(random(2, width-2), random(2, height/8-2));
    newPosition = physics.screenToWorld(newPosition);
    sand[i].setPosition(newPosition);
    sand[i].SetLinearDamping(1);
  }
}

