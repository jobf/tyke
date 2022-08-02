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
		musicFadeOutCountDown = new CountDown(0.2, () -> reduceMusicGain(), true);
		sounds = [];
		trace('initialized SoundManager');
		isUpdating = true;
	}

	/**
		can only be called after lime preload complete
	**/
	public function playMusic(assetPath:String) {
		trace('called playMusic()');
		loadingMusic = Assets.loadAudioBuffer(assetPath);
		loadingMusic.onComplete(buffer -> {
			music = new AudioSource(buffer);
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

	public function stopMusic() {
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

	function reduceMusicGain():Void {
		trace('reduceMusicGain ${music.gain}');
		final fadeIncrement = 0.1;
		var nextGain = music.gain - fadeIncrement;
		if (nextGain < 0) {
			nextGain = 0;
		}
		music.gain = nextGain;
		if (music.gain <= 0) {
			music.stop();
			isStoppingMusic = false;
			isMusicPlaying = false;
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
}
