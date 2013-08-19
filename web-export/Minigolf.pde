
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

float mousedir = 0;

PVector [] mouseVecHistory;
PVector mouseVec;

PVector hole;
PVector startingPoint;

int counter = 0;

Boolean inHole = false;

int hitDelay = 60;
int hitDelayCounter = hitDelay;


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

  mouseVecHistory = new PVector[10];
  for (int i=0;i<mouseVecHistory.length;i++)
  {
    mouseVecHistory[i]= new PVector(1, 1);
  }
  mouseVec = new PVector(1, 1);

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
  // now an array of crate sounds
  crateSounds = new AudioPlayer[balls.length];
  for (int i=0;i<balls.length;i++) {
    crateSounds[i] = maxim.loadFile("crate2.wav");
    crateSounds[i].setLooping(false);
  }

  // collision callbacks
  detector = new CollisionDetector (physics, this);
}


void draw() {
  // draw backgrounds
  noStroke();
  // draw startup dialog
  if (!userHasTriggeredAudio) {
    fill(0, 0, 120);
    rect(0, 0, width, height);
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    fill(0);
    text("Tap to start", width/2+1, height/2+1);
    fill(255);
    text("Tap to start", width/2, height/2);

  }
  // draw main background
  else {
    int alpha = 255;
    fill(0, alpha);
    image(groundImg, width/2, height/2);
    //background(207,116,108);
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
  image(holeImg, 0, 0);
  popMatrix();
  image(startingPointImg, startingPoint.x, startingPoint.y);


  if (inHole) {
    // draw balls
    pushMatrix();
    translate(hole.x, hole.y);
    // Fancy ball graphics:

    // (shadow)
    pushMatrix();
    fill(0, 70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.6, ballRadius*2.6);
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



  hitDelayCounter++;

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


    // ball drops in hole
    if (dist(ballPos.x, ballPos.y, hole.x, hole.y) <= holeRadius * .7  && speed <= 1.5) {
      //println("Won  " + speed);
      physics.getWorld().DestroyBody(balls[i]);
      balls = concat(subset(balls, 0, i), subset(balls, i+1, balls.length));
      inHole = true;
      levelRunning = false;
    }


    // draw balls
    pushMatrix();
    translate(ballPos.x, ballPos.y);
    // Fancy ball graphics:

    // (shadow)
    pushMatrix();
    fill(0, 70);
    translate(.1*ballRadius, .1*ballRadius);
    ellipse(0, 0, ballRadius*2.6, ballRadius*2.6);
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
    if (dist(mouseX, mouseY, ballPos.x, ballPos.y) <= 30 && speed <= .075 * ballRadius)
    {
      if (hitDelayCounter > hitDelay) {
        Vec2 impulse = new Vec2(mouseVec.y*.0002*sq(ballRadius), mouseVec.x*.0002*sq(ballRadius));
        balls[i].applyImpulse(impulse, balls[i].getWorldCenter());
        counter++;
        hitDelayCounter = 0;
      }
    }
  }

  drawLevel();



  if (!levelRunning) {
    textSize(32);
    textAlign(CENTER);
    PFont mono;
    mono = loadFont("monospace"); // available fonts: sans-serif,serif,monospace,fantasy,cursive
    textFont(mono);
    fill(0);
    text("Tap for next level", width/2+1, height/2+1);
    fill(255);
    text("Tap for next level", width/2, height/2);
  }



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


  for (i = 0; i < block.length; i++) {
    rect();
  }
}



void drawLevel() {
  //walls
  fill(255);
  rect(40, 40, width-80, 20); //horizontal bar
  rect(40, 40, 20, height-80); //vertical bar
  rect(40, height-60, width-80, 20); //horizontal bar
  rect(width-60, 40, 20, height-80); //vertical bar
  
  
  if (currentLevel == 2) {
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
  
  
  if (currentLevel == 3) {
    fill(255);
    stroke(255);
    drawPolygon(realPilatus);
    drawPolygon(pilatusTriangle);
  }
  
  if (currentLevel == 4) {
    fill(255);
    stroke(255);
    drawPolygon(EckTeil);
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
  
  
  // Level 3 physics
  if (currentLevel == 3) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(100, 500);
    buildPolygonBody(realPilatus);
    buildPolygonBody(pilatusTriangle);
  }

  // Level 4 physics
  if (currentLevel == 4) {
    hole = new Vec2(400, 120);
    startingPoint = new Vec2(100, 500);
    buildPolygonBody(EckTeil);
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
  
  

  //create a new ball
  physics.setDensity(10.0);
  Body newBall = physics.createCircle(width-100, height-100, ballRadius);
  newBall.SetLinearDamping(1.2);
  balls = append(balls, newBall);
}


void buildPolygonBody(float[][] polygons) {
  for (var j = 0; j < polygons.length; j++) {
    block = append(block, physics.createPolygon(polygons[j]));
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

  //println (mouseX + ", " + mouseY + ", ");
}


void startNextLevel() {
  // reset if last level is reached 
  if (currentLevel >= 10) currentLevel = 0;

  levelRunning = true;
  inHole = false;
  currentLevel++;

  // to do: maybe display the labyrinth after completing
  buildLevel();
  resetBallPosition();
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
    resetBallPosition();
  }
  if (keyCode == 50) {
    currentLevel = 2;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 51) {
    currentLevel = 3;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 52) {
    currentLevel = 4;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 53) {
    currentLevel = 5;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 54) {
    currentLevel = 6;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 55) {
    currentLevel = 7;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 56) {
    currentLevel = 8;
    buildLevel();
    resetBallPosition();
  }
  if (keyCode == 57) {
    currentLevel = 9;
    buildLevel();
    resetBallPosition();
  }
  if (key == 'a') {
    String[] params = {"q", "test"};
    post_to_url("http://google.com", params, "post");
  }
  
}


void collision(Body b1, Body b2, float impulse)
{
  /*  crateSounds[whichSoundLooper].cue(0);
   //crateSounds[whichSoundLooper].speed(0.25 + (impulse / 250));// 10000 as the crates move slower??
   crateSounds[whichSoundLooper].volume(impulse);
   crateSounds[whichSoundLooper].play();
   
   whichSoundLooper++;
   if (whichSoundLooper >= balls.length) {
   whichSoundLooper = 0;
   }*/
}

void resetBallPosition() {
  for (var i = 0; i < balls.length; i++) {
    Vec2 position = new Vec2(startingPoint.x, startingPoint.y);
    position = physics.screenToWorld(position);
    balls[i].setPosition(position);

    Vec2 velocity = new Vec2(0, 0);
    balls[i].setLinearVelocity(velocity);
  }
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

