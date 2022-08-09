package tyke.jam;

import haxe.ds.Vector;
import lime.media.AudioBuffer;
import lime.app.Future;
import tyke.Loop.CountDown;
import lime.utils.Assets;
import lime.media.AudioSource;

class SoundManager {
	var musicFadeOutCountDown:CountDown;
	var music:AudioSource;
	var sounds:Map<Int, Sound>;
	var isStoppingMusic:Bool = false;
	var loadingMusic:Future<AudioBuffer>;
	var isUpdating:Bool;

	public var isMusicPlaying(default, null):Bool;

	public function new() {
		musicFadeOutCountDown = new CountDown(0.032, () -> reduceMusicGain(), true);
		sounds = [];
		trace('initialized SoundManager');
		isUpdating = true;
	}

	var globalGain = 1.0;

	public function mute(){
		globalGain = 0;
		if(music != null){
			music.gain = globalGain;
		}
	}

	/**
		can only be called after lime preload complete
	**/
	public function playMusic(assetPath:String) {
		trace('called playMusic()');
		loadingMusic = Assets.loadAudioBuffer(assetPath);
		loadingMusic.onComplete(buffer -> {
			music = new AudioSource(buffer, 0,null, 1000);
			music.gain = globalGain;
			trace('init music AudioSource');
			music.play();
			trace('called music.play()');
			isMusicPlaying = true;
		});
		loadingMusic.onError(d -> {
			trace('error');
			trace(d);
		});
		loadingMusic.onProgress((i1, i2) -> {
			trace('loading music progress $i1 $i2');
		});
	}

	/**
		can only be called after lime preload complete
	**/
	public function loadSounds(soundPaths:Map<Int, String>) {
		for (key in soundPaths.keys()) {
			var soundPath = soundPaths[key];
			var loadingSound = Assets.loadAudioBuffer(soundPath);
			loadingSound.onComplete(buffer -> {
				sounds[key] = new Sound(5, buffer);
				sounds[key].setGain(globalGain);
				trace('init sound $soundPath');
			});
			loadingSound.onError(d -> {
				trace('error');
				trace(d);
			});
			loadingSound.onProgress((i1, i2) -> {
				trace('loading sound progress $i1 $i2');
			});
		}
	}

	public function playSound(key:Int) {
		if (sounds.exists(key)) {
			sounds[key].play();
		}
	}

	public function stopMusic(onFinished:Void->Void=null) {
		onFadeOutComplete = onFinished;
		if (isMusicPlaying && !isStoppingMusic) {
			trace('start fade out music');
			isStoppingMusic = true;
			musicFadeOutCountDown.reset();
		}
		
	}


	public function update(elapsedSeconds:Float) {
		if (isUpdating) {
			if (isStoppingMusic) {
				musicFadeOutCountDown.update(elapsedSeconds);
			}
		}
	}

	public function dispose(){
		if(music != null){
			music.stop();
		}
	}

	function reduceMusicGain():Void {
		trace('reduceMusicGain ${music.gain}');
		final fadeIncrement = 0.1;
		var nextGain = music.gain - fadeIncrement;
		if (nextGain < 0) {
			nextGain = 0;
		}
		music.gain = nextGain;
		if (music.gain <= 0) {
			onMusicFadedOut();

		}
	}

	var onFadeOutComplete:Void->Void;
	function onMusicFadedOut(){
		music.stop();
		isStoppingMusic = false;
		isMusicPlaying = false;
		if(onFadeOutComplete != null){
			onFadeOutComplete();
		}
	}

	public function pause(willPauseAudio:Bool) {
		isUpdating = !willPauseAudio;
		if (isMusicPlaying) {
			if (willPauseAudio) {
				trace('music.pause()');
				music.pause();
			}
			else{
				trace('music.play()');
				music.play();
			}
		}
	}
}

class Sound {
	var channels:Vector<Channel>;

	public function new(numChannels:Int, buffer:AudioBuffer) {
		channels = new Vector<Channel>(numChannels);
		for (i in 0...numChannels) {
			channels[i] = new Channel(buffer);
		}
	}

	public function play() {
		for (c in channels) {
			if (!c.isPlaying) {
				c.play();
				break;
			}
		}
	}

	public function setGain(gain:Float){
		for(c in channels){
			c.setGain(gain);
		}
	}
}

class Channel {
	public var isPlaying(default, null):Bool;

	var source:AudioSource;

	public function new(buffer:AudioBuffer) {
		var offset = 0;
		var length = null;
		var loops = 1;
		this.source = new AudioSource(buffer, offset, length, loops);
		isPlaying = false;
	}

	public function play() {
		if (!isPlaying) {
			source.play();
		}
	}

	public function setGain(gain:Float){
		source.gain = gain;
	}
}
