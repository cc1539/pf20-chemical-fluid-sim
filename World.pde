
public class World {
  
  public float gravity = 1e-2;
  
  private ArrayList<Part> parts = new ArrayList<Part>();
  private ArrayList<Part>[][] grid;
  private Part.Properties[] types = new Part.Properties[500];
  
  public float[][] cohesion = new float[types.length][types.length];
  public int[][] reaction = new int[types.length][types.length];
  
  public World(int w, int h) {
    grid = new ArrayList[w][h];
    for(int i=0;i<w;i++) {
    for(int j=0;j<h;j++) {
      grid[i][j] = new ArrayList<Part>();
    }
    }
    for(int i=0;i<types.length;i++) {
      types[i] = new Part.Properties();
    }
  }
  
  public void randomizeProperties() {
    colorMode(HSB);
    for(int i=0;i<types.length;i++) {
      types[i].su = random(2e-2,1);
      types[i].bu = random(2e-2,1);
      types[i].m = random(1,10);
      types[i].r = random(3,6);
      types[i].k = random(2e-2,2e-1)*1e-1;
      types[i].c = random(0,3);
      types[i].Tr = random(0,30);
      types[i].Tf = random(-.5,2);
      types[i].p0 = random(-2,5);
      
      types[i].shade = color(
          random(64,255),
          random(64,255),
          random(64,255));
          
      //types[i].shade = color(255.*i/types.length,255,255);
    }
    for(int i=0;i<types.length;i++) {
    for(int j=i;j<types.length;j++) {
      float value = (int)random(0,2)*2-1;
      cohesion[i][j] = value;
      cohesion[j][i] = value;
    }
    }
    for(int i=0;i<types.length;i++) {
    for(int j=0;j<types.length;j++) {
      reaction[i][j] = random(0,2)<1?(int)random(0,types.length):i;
    }
    }
  }
  
  public void add(Part part, int type) {
    
    part.chemical = new float[types.length];
    part.cohesion = cohesion;
    part.reaction = reaction;
    
    part.type = type;
    part.props.su = types[type].su;
    part.props.bu = types[type].bu;
    part.props.m = types[type].m;
    part.props.r = types[type].r;
    part.props.k = types[type].k;
    part.props.c = types[type].c;
    part.props.Tr = types[type].Tr;
    part.props.Tf = types[type].Tf;
    part.props.p0 = types[type].p0;
    part.props.shade = types[type].shade;
    
    parts.add(part);
  }
  
  public void remove(Part part) {
    parts.remove(part);
  }
  
  public void clear() {
    parts.clear();
  }
  
  public void updateNeighbors(float resolution) {
    for(Part part : parts) {
      part.resetNeighborhood();
    }
    for(int i=0;i<grid.length;i++) {
    for(int j=0;j<grid[0].length;j++) {
      grid[i][j].clear();
    }
    }
    for(Part part : parts) {
      int x = floor(part.x/resolution);
      if(x<0 || x>=grid.length) { continue; }
      int y = floor(part.y/resolution);
      if(y<0 || y>=grid[0].length) { continue; }
      grid[x][y].add(part);
    }
    for(Part part : parts) {
      int x = floor(part.x/resolution);
      int y = floor(part.y/resolution);
      for(int i=-1;i<=1;i++) {
      for(int j=-1;j<=1;j++) {
        int u=x+i; if(u<0||u>=grid.length) { continue; }
        int v=y+j; if(v<0||v>=grid[0].length) { continue; }
        for(Part neighbor : grid[u][v]) {
          part.considerNeighbor(neighbor);
        }
      }
      }
    }
  }
  
  public void resetDensity() {
    for(Part part : parts) {
      part.resetDensity();
    }
  }
  
  public void updatePressure() {
    for(Part part : parts) {
      part.updatePressure();
    }
  }
  
  public void interact(int options) {
    for(Part part : parts) {
      part.interact(options);
    }
  }
  
  public void updateType() {
    for(Part part : parts) {
      part.updateType();
    }
  }
  
  public void updateProperties(float rate) {
    for(Part part : parts) {
      int type = part.type;
      
      part.props.su += (types[type].su-part.props.su)*rate;
      part.props.bu += (types[type].bu-part.props.bu)*rate;
      part.props.m += (types[type].m-part.props.m)*rate;
      part.props.r += (types[type].r-part.props.r)*rate;
      part.props.k += (types[type].k-part.props.k)*rate;
      part.props.c += (types[type].c-part.props.c)*rate;
      part.props.Tr += (types[type].Tr-part.props.Tr)*rate;
      part.props.Tf += (types[type].Tf-part.props.Tf)*rate;
      part.props.p0 += (types[type].p0-part.props.p0)*rate;
      
      color next_color = lerpColor(part.props.shade,types[type].shade,rate);
      if(part.props.shade==(part.props.shade=next_color)) {
        part.props.shade = types[type].shade;
      }
      
    }
  }
  
  public void shuffle() {
    for(int i=0;i<parts.size();i++) {
      int j = (int)random(i,parts.size());
      if(i!=j) {
        Part temp = parts.get(i);
        parts.set(i,parts.get(j));
        parts.set(j,temp);
      }
    }
  }
  
  public void move() {
    for(Part part : parts) {
      part.capAcceleration(2);
      part.ay += gravity;
      part.move();
    }
  }
  
  public void draw(PGraphics g) {
    for(Part part : parts) {
      part.draw(g);
    }
  }
  
  public void applyBorder(float x0, float y0, float x1, float y1) {
    float bounce = 0.9;
    for(Part part : parts) {
      float x0r = x0+part.props.r;
      float x1r = x1-part.props.r;
      float y0r = y0+part.props.r;
      float y1r = y1-part.props.r;
      float x = part.x;
      float y = part.y;
      if(x<x0r||x>x1r){x=(x<x0r?x0r:x1r)*2-x;part.vx*=-bounce;}
      if(y<y0r||y>y1r){y=(y<y0r?y0r:y1r)*2-y;part.vy*=-bounce;}
      part.x = x;
      part.y = y;
    }
  }
  
  public void resetConcentration() {
    for(Part part : parts) {
      part.resetConcentration();
    }
  }
  
  public Part getClosestPart(float x, float y) {
    float min_dst2 = Float.MAX_VALUE;
    Part pick = null;
    for(Part part : parts) {
      float dx = x - part.x;
      float dy = y - part.y;
      float dst2 = dx*dx+dy*dy;
      if(dst2<min_dst2) {
        min_dst2 = dst2;
        pick = part;
      }
    }
    return pick;
  }
  
}
