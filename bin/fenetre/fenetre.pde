import processing.serial.*;
import processing.video.*;
import ddf.minim.*;

public class Entity{
  public float difficultyExpand;
  public float difficultyRecess;
  public float expandSpeed;
  public float recessSpeed;
  public float size;
  public int colorID; // color of entity
  public int x;
  public int y;
  
  public Entity(){
  }
  
  public void reset(){
    size = 0.1;
  }
  
  public void grow(float dt){
    size += expandSpeed * dt;
  }
  
  public void decrease(float dt){
    size -= recessSpeed * dt;
  }
  
  public void render(){
    if(size <= 0) return;
    fill(colors[colorID][0], colors[colorID][1], colors[colorID][2]);
    rect(x-size*0.5, y-size*0.5, size, size);
  }
  
  public Boolean coverScreen(){
    return  (x + size*0.5) > width &&
            (x - size*0.5) < 0 &&
            (y + size*0.5) > height &&
            (y - size*0.5) < 0;
  }
};


// COLORS CONST
int[][] colors = {
                {216, 109, 129}, //rose
                {0xf7, 0Xfe, 0x2e}, //jaune
                {0x00, 0x00, 0x00}, //noir
                {0xff, 0xff, 0xff}, //blanc
                {211, 81, 47}, //orange
                {101, 197, 125}, //vert
                {88, 149, 193}  //bleu
              };
              
int[][] buttonsColorGroups = {
  {0,11,19}, //rose
  {1,7,15},  //jaune
  {2,5,10,}, //noir
  {3,16,17}, //blanc
  {6,13,18}, //orange
  {8,9,12},  //vert
  {4,14,20}  //bleu
};

// LD tweaks
int[] maxSimultaneousObjPerLevel = {1, 2, 3, 4, 5};
int[] destroyPerLevel = {6, 8, 10, 12, 25};
float baseExpandSpeed = 20;//5;
float maxRecessSpeed = 20;
float minRecessSpeed = 5;

// TIME MANAGEMENT
float dt;
float lastTime;

int level;
int difficulty;
int nbDestroyed;
float popFreq = 4; // time for pop (seconds)
float popTimer;
boolean showDebug = false;

ArrayList<Entity> entities;
Capture cam = null;
Minim minim;
AudioPlayer[] audio = new AudioPlayer[7];

boolean sketchFullScreen() {
  return true;
}

void setup() {
  size(displayWidth, displayHeight);
  background(0xbbbbbb);
  noStroke();
  noCursor();
  
  entities = new ArrayList<Entity>();
  
  lastTime = millis();
  dt = 0;
  initInputs();
  initCam();
  initAudio();
  reset();
}

void reset(){
  level = 0;
  difficulty = 0;
  popTimer = 0;
  nbDestroyed = 0;
  entities.clear();
  background(0xffffff);
  
  //reset inputs
  for(int i=0; i<23; i++){
    buttons_states[i] = 1;
  }
  for(int i=0; i<audio.length; i++){
    audio[i].pause();
  }
  
  gameState = STATE_INGAME;
  gameOverElapsed = 0;
  
  popEntity();
}

int STATE_INGAME = 0;
int STATE_GAME_OVER = 1;
int gameState = STATE_INGAME;
float alpha = 1;
float gameOverDuration = 3;
float gameOverElapsed = 0;
void gameOver(){
  gameState = STATE_GAME_OVER;
  gameOverElapsed = 0;
}

void updateGameOver(float dt){
  gameOverElapsed += dt;
  float ratio = gameOverElapsed/1.5;
  alpha = lerp(0, 1, ratio);
  
  fill(0, 0, 0, alpha);
  rect(0, 0, width, height);
  if(gameOverElapsed > gameOverDuration){
    reset();
  }
}

void initAudio(){
  // we pass this to Minim so that it can load files from the data directory
  minim = new Minim(this);
  
  // loadFile will look in all the same places as loadImage does.
  // this means you can find files that are in the data folder and the 
  // sketch folder. you can also pass an absolute path, or a URL.
  audio[0] = minim.loadFile("sound/note_0.wav"); audio[0].loop(); audio[0].pause();
  audio[1] = minim.loadFile("sound/note_1.wav"); audio[1].loop(); audio[1].pause();
  audio[2] = minim.loadFile("sound/note_2.wav"); audio[2].loop(); audio[2].pause();
  audio[3] = minim.loadFile("sound/note_3.wav"); audio[3].loop(); audio[3].pause();
  audio[4] = minim.loadFile("sound/note_4.wav"); audio[4].loop(); audio[4].pause();
  audio[5] = minim.loadFile("sound/note_5.wav"); audio[5].loop(); audio[5].pause();
  audio[6] = minim.loadFile("sound/note_6.wav"); audio[6].loop(); audio[6].pause();
}

void initCam(){
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
  } else {
    println("Available cameras:"+cameras.length);
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, 1280, 960, 30);
    cam.start();     
  }
}

Serial myPort; // The serial port
void initInputs(){
   // List all the available serial ports
   println(Serial.list());
   // I know that the first port in the serial list on my mac
   // is always my  Arduino, so I open Serial.list()[0].
   // Open whatever port is the one you're using.
   myPort = new Serial(this, Serial.list()[0], 9600);
   // don't generate a serialEvent() unless you get a newline character:
   println("Initialized inputs");
   myPort.bufferUntil('\n');
}

byte[] buttons_states = new byte[23];
void readInputs(){
  if(myPort.available() == 0) return;
  
  //println("Reading inputs (available bytes:"+myPort.available()+")");
  while(myPort.available() > 0) {
    String states_string = myPort.readStringUntil('\n');
    if (states_string != null) {
      //println(states_string);
      
      // feed the state buffer
      //print("verif:");
      for(int i=0; i<23; i++){
        buttons_states[i] = (byte)(states_string.charAt(i) - '0'); //convert back to number
        //print(buttons_states[i]);
      }
      //println();
    }
  }
}

Boolean colorPressed(int colorID){
  // loop through buttons of this color
  // and return true if at least one of them is pressed
  for(int i=0; i<buttonsColorGroups[colorID].length; i++){
    int buttonId = buttonsColorGroups[colorID][i];
    if(buttons_states[buttonId] == 0) return true;
  }
  return false;
}

void renderCam(){
  if(cam == null) return;
  
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0);
  filter(GRAY);
  // The following does the same, and is faster when just drawing the image
  // without any additional resizing, transformations, or tint.
  //set(0, 0, cam);
}

void debug(){
  // display entities colors
  String s = "Entities:"+entities.size();
  for(int i=0; i<entities.size(); i++){
    Entity e = entities.get(i);
    s += "\n"+e.colorID+":"+e.expandSpeed+", "+e.recessSpeed+"/"+e.difficultyExpand+", "+e.difficultyRecess+"\n";
  }
  
  s+="\n";
  // display buttons states
  for(int c=0; c<colors.length; c++){
    for(int i=0; i<buttonsColorGroups[c].length; i++){
      int buttonId = buttonsColorGroups[c][i];
      s+= buttons_states[buttonId] +",";
    }
    s+="\n";
  }
  
  s+="\n";
  //s+="level:"+level+"\nmax entities:"+maxSimultaneousObjPerLevel[level];
  fill(0);
  rect(100, 10, 150, 200);
  fill(255, 255, 255);
  text(s, 100, 10, 150, 200);  // Text wraps within text box
}

void keyPressed() {
  if(key == 'd') showDebug = !showDebug;
}

void draw() {
  background(0xdddddd);
  renderCam();
    
  if(gameState == STATE_INGAME){
    readInputs();
    
    popTimer += dt;
    if(popTimer > popFreq){
      popEntity();
      popTimer -= popFreq;
    }
    
    if(nbDestroyed > destroyPerLevel[level]){
      nextLevel();
    }
    
    // loop backwards to render first elements in front of last ones
    for(int i=entities.size()-1; i>=0; i--){
      Entity e = entities.get(i);
      if(colorPressed(e.colorID)) e.decrease(dt);
      else e.grow(dt);
      e.render();
      
      if(!audio[e.colorID].isPlaying() && !colorPressed(e.colorID)){
        audio[e.colorID].loop();
      } 
      
      if(e.coverScreen()){
        println("GAME OVER - RESET");
        gameOver();
        break;
      }
      
      // pause audio for pressed colors (if color actually playing)
      for(int c=0; c<colors.length; c++){
        if(colorPressed(c) && audio[c].isPlaying()) audio[c].pause();
      }
    
      if(e.size <= 0){
        removeEntity(e);
      }
    }
    
    // pause audio for pressed colors
    for(int c=0; c<colors.length; c++){
      if(colorPressed(c)) audio[c].pause();
    }
  }else{
    updateGameOver(dt);
  }
  
  // register new time
  dt = (millis() - lastTime) * 0.001;
  lastTime = millis();
  
  if(showDebug) debug();
}

void removeEntity(Entity e){
  entities.remove(e);
  nbDestroyed++;
}

void nextLevel(){
  nbDestroyed = 0;
  level++;
  level = min(level, maxSimultaneousObjPerLevel.length-1);
  println("LAUNCHING LEVEL "+level);
}

void popEntity(){
  /////// We can't have more entities in game than number of colors we have
  if(entities.size() > maxSimultaneousObjPerLevel[level]) return;
  
  Entity newEntity = new Entity();
  newEntity.size = 0.1;
  
  // compute expand and recess speed using difficulty of this object
  int[] caracs = {difficulty, 0};
  /*int caracPoints = difficulty;
  while(caracPoints > 0){
    float rnd = random(1);
    caracs[round(rnd)]++;
    caracPoints--;
  }*/
  float expandBonusFactor = 3;
  float recessMalusFactor = 15;
  newEntity.expandSpeed = baseExpandSpeed + caracs[0]*expandBonusFactor;
  newEntity.recessSpeed = max(minRecessSpeed, maxRecessSpeed - caracs[1]*recessMalusFactor);
  newEntity.difficultyExpand = caracs[0];
  newEntity.difficultyRecess = caracs[1];
  
  newEntity.x = int(random(width));
  newEntity.y = int(random(height));
  
  // make sure we don't use a color that's already spawned
  int colorID = int(random(colors.length));
  Boolean colorSelected = false;
  while(!colorSelected){
    colorSelected = true;
    for(int i=0; i<entities.size(); i++){
      Entity ent = entities.get(i);
      if(ent.colorID == colorID){
        //println("already have an entity of color "+colorID);
        colorID = (colorID+1)%colors.length;
        //println("now trying with color:"+colorID);
        colorSelected = false;
        break;
      }
    }
  }
  newEntity.colorID = colorID;
  
  entities.add(newEntity);
  difficulty++;
  
  println("created new entity:\n\t"+newEntity.colorID+"\n\texpand:"+newEntity.expandSpeed+"\n\trecess:"+newEntity.recessSpeed);
}
