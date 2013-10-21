
const int button_pins[] = {14,15,16,17,18,19,20,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51};
uint8_t button_states[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
const int nbButtons = 23;

void setup() {  
  Serial.begin(9600);
  // initialize the pushbutton pin as an input:
  for(int i=0; i<nbButtons; i++){
    pinMode(button_pins[i], INPUT_PULLUP);
  }
}

void loop(){
  delay(10);
  
  // read the state of the pushbuttons
  boolean state_changed = false;
  for(int i=0; i<nbButtons; i++){
    uint8_t state = digitalRead(button_pins[i]);
    if(state != button_states[i]){
      state_changed = true;
      button_states[i] = state;
    }
  }
  
  // send the bytes if at least one button changed state
  if(state_changed){
    for(int i=0; i<nbButtons; i++){
      Serial.print(button_states[i]);
    }
    Serial.print('\n');
  }
}
