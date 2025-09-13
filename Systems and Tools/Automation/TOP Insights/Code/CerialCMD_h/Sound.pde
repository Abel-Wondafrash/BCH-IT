import ddf.minim.*;
import ddf.minim.ugens.*;

class Sound {
  Minim minim;
  AudioOutput out;
  Oscil alertTone, easeTone;

  boolean isMuted;

  Sound () {
    minim = new Minim (this);
    out = minim.getLineOut ();

    alertTone = new Oscil (1000, 0.6);
    easeTone = new Oscil (600, 0.6);
  }

  void play (Oscil oscil) {
    if (isMuted) return;
    oscil.patch (out);
    delay (100);
    oscil.unpatch (out);
  }

  void mute () {
    isMuted = true;
  }
  void unmute () {
    isMuted = false;
  }
  
  void alert () {
    play (alertTone);
    delay (50);
    play (alertTone);
  }
  void ease () {
    play (easeTone);
    delay (50);
    play (easeTone);
  }
}
