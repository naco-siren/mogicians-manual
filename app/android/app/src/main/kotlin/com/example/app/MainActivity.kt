// The package is kept as `com.example.app` (the name this activity shipped
// with since 2017) so that existing home-screen shortcuts keep resolving.
package com.example.app

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity is a FlutterActivity that shares its FlutterEngine with
// the media playback service (audio_service).
class MainActivity : AudioServiceActivity()
