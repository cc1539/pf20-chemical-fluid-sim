
public static class Part {
  
  public static final int DENSITY   = 1<<0;
  public static final int PRESSURE  = 1<<1;
  public static final int CHEMICAL  = 1<<2;
  public static final int VISCOSITY = 1<<3;
  public static final int REPULSION = 1<<4;
  public static final int TENSION   = 1<<5;
  public static final int CONDUCT   = 1<<6;
  
  private final ArrayList<Part> neighbors = new ArrayList<Part>();
  
  public float x; // x position
  public float y; // y position
  public float vx; // x velocity
  public float vy; // y velocity
  public float ax; // x acceleration
  public float ay; // y acceleration
  
  public static class Properties {
    
    public float su; // shear viscosity
    public float bu; // bulk viscosity
    public float m; // mass
    public float r; // interaction radius
    public float k; // repulsion rigidity
    public float c; // chemical concentration
    public float Tr; // surface tension density range
    public float Tf; // surface tension maximum force
    public float p0; // target pressure
    
    public color shade;
  }
  
  public int type;
  public Properties props = new Properties();
  
  public float d; // density
  public float p; // pressure
  public float t; // temperature
  public float[] chemical; // chemical concentration
  
  public float[][] cohesion; // stickiness matrix
  public int[][] reaction; // transmutation matrix
  
  public Part() {}
  
  public Part(float x, float y) {
    this();
    this.x = x;
    this.y = y;
  }
  
  public Part(float x, float y, float vx, float vy) {
    this(x,y);
    this.vx = vx;
    this.vy = vy;
  }
  
  public void capAcceleration(float limit) {
    float accel = ax*ax+ay*ay;
    if(accel>limit*limit) {
      accel = sqrt(accel);
      ax /= accel;
      ay /= accel;
    }
  }
  
  public void move() {
    x += vx += ax;
    y += vy += ay;
    ax = 0;
    ay = 0;
  }
  
  public void draw(PGraphics g) {
    float d = max(2,props.r*2-5);
    g.noStroke();
    g.fill(props.shade);
    g.ellipse(x,y,d,d);
  }
  
  public void resetNeighborhood() {
    neighbors.clear();
  }
  
  public void considerNeighbor(Part part) {
    if(this!=part && !neighbors.contains(part)) {
      float dx = x - part.x;
      float dy = y - part.y;
      if(dx!=0 || dy!=0) {
        float dst2 = dx*dx+dy*dy;
        float rads = props.r+part.props.r;
        if(dst2<rads*rads) {
          this.neighbors.add(part);
          part.neighbors.add(this);
        }
      }
    }
  }
  
  public void interact(int options) {
    for(Part part : neighbors) {
      interact(part,options);
    }
  }
  
  public void interact(Part part, int options) {
    float dx = x - part.x;
    float dy = y - part.y;
  
    float dst2 = dx*dx+dy*dy;
    float rads = props.r+part.props.r;
    
    float dst = sqrt(dst2);
    float force = 0;
    
    rads += max(max(t,part.t),-min(props.r,part.props.r)/3);
    
    float q = (1-rads/dst)*.5;
    float h = (1-dst/rads)*.5;
  
    if((options&DENSITY)!=0) {
      part.d += this.props.m*h;
      this.d += part.props.m*h;
    }
    
    if((options&PRESSURE)!=0) {
      force += min(((p+part.p)/2-min(props.p0,part.props.p0))*h*.1,.5);
    }
    
    if((options&CHEMICAL)!=0) {
      part.chemical[this.type] += this.props.c*q;
      this.chemical[part.type] += part.props.c*q;
    }
    
    if((options&VISCOSITY)!=0) {
      float dvx = vx - part.vx;
      float dvy = vy - part.vy;
      if(dvx!=0 || dvy!=0) {
        float speed = sqrt(dvx*dvx+dvy*dvy);
        float bu = abs(dvx*vx+dvy*vy)/(speed*dst)*min(props.bu,part.props.bu);
        float su = abs(dvx*vy-dvy*vx)/(speed*dst)*min(props.su,part.props.su);
        float u = max(min((bu+su)/2,.5),0);
        dvx *= u;
        dvy *= u;
        part.vx += dvx;
        part.vy += dvy;
        vx -= dvx;
        vy -= dvy;
      }
    }
    
    if((options&REPULSION)!=0) {
      force -= q*max(props.k,part.props.k);
    }
    
    if((options&TENSION)!=0) {
      float factor = 1-(p+part.p)/(2*max(props.Tr,part.props.Tr));
      if(factor>0) {
        force += min(1e-1,factor*cohesion[type][part.type]*min(props.Tf,part.props.Tf));
      }
    }
    
    if((options&CONDUCT)!=0) {
      // conduct temperature
      float dt = (part.t-t)*.1;
      t += dt;
      part.t -= dt;
    }
    
    if(force!=0) {
      force = min(max(force,-5e-1),5e-1);
      dx *= force;
      dy *= force;
      ax += dx/props.m;
      ay += dy/props.m;
      part.ax -= dx/part.props.m;
      part.ay -= dy/part.props.m;
    }
    
  }
  
  public void resetDensity() {
    d = props.m;
  }
  
  public void updatePressure() {
    p = d;
  }
  
  public void resetConcentration() {
    for(int i=0;i<chemical.length;i++) {
      chemical[i] = 0;
    }
  }
  
  public void updateType() {
    int choice = 0;
    float max_concen = -Float.MAX_VALUE;
    for(int i=0;i<chemical.length;i++) {
      if(chemical[i]>max_concen) {
        max_concen = chemical[i];
        choice = i;
      }
    }
    if(choice!=-1 && chemical[choice]>(props.c-t)) {
      type = reaction[type][choice];
    }
  }
  
}
