
int IPF = 2;

boolean running = true;

World world;
float resolution = 6;

int type = 0;
int timeout = 0;
StringBuilder str_type = new StringBuilder();

int temp_unit;
float temp_factor = 0.1;
float temp;

static ArrayList<String> console = new ArrayList<String>();
static int console_show_time = 0;
static int console_max_lines = 20;

public static void println(String line) {
  PApplet.println(line);
  console.add(line);
  if(console.size()>console_max_lines) {
    console.remove(0);
  }
  console_show_time = 700;
}

void selectType() {
  timeout = 0;
  int target_type = parseInt(str_type.toString());
  if(target_type<world.types.length) {
    type = target_type;
    println("Type selected: "+type);
  } else {
    println("Type invalid: "+target_type);
  }
  str_type.setLength(0);
}

void setup() {
  size(840,640);
  noSmooth();
  
  world = new World(ceil(width/resolution),ceil(height/resolution));
  world.randomizeProperties();
}

void mouseWheel(MouseEvent e) {
  temp_unit -= e.getCount();
  temp = temp_unit*temp_factor;
  println("set temperature to: "+temp);
}

void keyPressed() {
  if(key>='0' && key<='9') {
    timeout = 30;
    str_type.append(key);
  } else {
    if(timeout>0) {
      selectType();
    }
    switch(key) {
      case 'r': {
        world.randomizeProperties();
        println("physics randomized");
      } break;
      case ' ': {
        running = !running;
        if(running) {
          println("simulation resumed");
        } else {
          println("simulation paused");
        }
      } break;
      case 'i': {
        
      } break;
      case 'c': {
        world.clear();
      } break;
      case 'q': { // force positive adhesion
        for(int i=0;i<world.types.length;i++) {
        for(int j=0;j<world.types.length;j++) {
          if(i!=j) {
            world.cohesion[i][j] = abs(world.cohesion[i][j]);
          }
        }
        }
      } break;
      case 'e': { // force negative adhesion
        for(int i=0;i<world.types.length;i++) {
        for(int j=0;j<world.types.length;j++) {
          if(i!=j) {
            world.cohesion[i][j] = -abs(world.cohesion[i][j]);
          }
        }
        }
      } break;
    }
  }
}

void draw() {
  
  if(timeout>0 && --timeout==0) {
    selectType();
  }
  
  float mouse_radius = 40;
  
  if(mousePressed) {
    
    float x = mouseX;
    float y = mouseY;
    float vx = (float)(mouseX-pmouseX)/IPF;
    float vy = (float)(mouseY-pmouseY)/IPF;
    
    if(mouseButton==LEFT) {
      
      if(timeout>0) {
        selectType();
      }
      
      for(int i=0;i<10;i++) {
        float angle = random(0,TWO_PI);
        float range = sqrt(random(0,1))*mouse_radius;
        world.add(new Part(
          x+range*cos(angle),
          y+range*sin(angle),
        vx,vy),type);
      }
      
    } else if(mouseButton==RIGHT) {
      
      for(Part part : world.parts) {
        float dx = x - part.x;
        float dy = y - part.y;
        if(dx*dx+dy*dy<mouse_radius*mouse_radius) {
          part.vx = vx;
          part.vy = vy;
        }
      }
      
    } else if(mouseButton==CENTER) {
      
      for(Part part : world.parts) {
        float dx = x - part.x;
        float dy = y - part.y;
        if(dx*dx+dy*dy<mouse_radius*mouse_radius) {
          part.t += temp;
        }
      }
      
    }
    
  } else {
    
  }
  
  background(0);
  
  if(running) {
    for(int i=0;i<IPF;i++) {
      world.shuffle();
      world.updateNeighbors(resolution*2);
      world.resetDensity();
      world.resetConcentration();
      world.interact(0
        |Part.DENSITY
        |Part.CHEMICAL
        |Part.CONDUCT
      );
      world.updatePressure();
      world.updateType();
      world.updateProperties(1e-1);
      world.interact(0
        |Part.PRESSURE
        |Part.VISCOSITY
        |Part.REPULSION
        |Part.TENSION
      );
      world.move();
      world.applyBorder(0,0,width,height);
    }
  }
  
  world.draw(g);
  
  if(!running) {
    Part pick = world.getClosestPart(mouseX,mouseY);
    if(pick!=null) {
      textAlign(LEFT,BOTTOM);
      fill(255);
      text("Type: "+pick.type,4,height-4);
    }
  }
  
  if(console_show_time>0) {
    textAlign(LEFT,TOP);
    fill(255,min(console_show_time,255));
    for(int i=0;i<console.size();i++) {
      text(console.get(i),4,4+14*i);
    }
    console_show_time--;
  }
  
  surface.setTitle("FPS: "+frameRate);
}
