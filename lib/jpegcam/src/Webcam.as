﻿package {
	/* JPEGCam v1.0.9 */
	/* Webcam library for capturing JPEG images and submitting to a server */
	/* Copyright (c) 2008 - 2009 Joseph Huckaby <jhuckaby@goldcartridge.com> */
	/* Licensed under the GNU Lesser Public License */
	/* http://www.gnu.org/licenses/lgpl.html */
    
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
    import flash.events.*;
	import flash.utils.*;
    import flash.media.Camera;
    import flash.media.Video;
	import flash.external.ExternalInterface;
	import flash.net.*;
	import flash.system.Security;
    import flash.system.SecurityPanel;
	import flash.media.Sound;
    import flash.media.SoundChannel;
	import flash.geom.Matrix;
	import com.adobe.images.JPGEncoder;

    public class Webcam extends Sprite {
        private var video:Video;
		private var encoder:JPGEncoder;
		private var snd:Sound;
		private var channel:SoundChannel = new SoundChannel();
		private var jpeg_quality:int;
		private var video_width:int;
		private var video_height:int;
		private var server_width:int;
		private var server_height:int;
		private var camera:Camera;
		private var bmp:Bitmap;
		private var bmpdata:BitmapData;
		private var url:String;
		private var stealth:int;
        
        public function Webcam() {
			// class constructor
			flash.system.Security.allowDomain("*");
			var flashvars:Object = LoaderInfo(this.root.loaderInfo).parameters;
			video_width = Math.floor( flashvars.width );
			video_height = Math.floor( flashvars.height );
			server_width = Math.floor( flashvars.server_width );
			server_height = Math.floor( flashvars.server_height );
			
            stage.scaleMode = StageScaleMode.NO_SCALE;
			// stage.scaleMode = StageScaleMode.EXACT_FIT;
            stage.align = StageAlign.TOP_LEFT;
			stage.stageWidth = Math.max(video_width, server_width);
			stage.stageHeight = Math.max(video_height, server_height);
			
			// Hack to auto-select iSight camera on Mac (JPEGCam Issue #5, submitted by manuel.gonzalez.noriega)
			// From: http://www.squidder.com/2009/03/09/trick-auto-select-mac-isight-in-flash/
			var cameraIdx:int = -1;
			for (var idx = 0, len = Camera.names.length; idx < len; idx++) {
				if (Camera.names[idx] == "USB Video Class Video") {
					cameraIdx = idx;
					idx = len;
				}
			}
            if (cameraIdx > -1) camera = Camera.getCamera( String(cameraIdx) );
            else camera = Camera.getCamera();
						            
            if (camera != null) {
                camera.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
                video = new Video( Math.max(video_width, server_width), Math.max(video_height, server_height) );
                video.attachCamera(camera);
                addChild(video);
				
				if ((video_width < server_width) && (video_height < server_height)) {
					video.scaleX = video_width / server_width;
					video.scaleY = video_height / server_height;
				}

				camera.setQuality(0, 100);
				camera.setKeyFrameInterval(10);
				camera.setMode( Math.max(video_width, server_width), Math.max(video_height, server_height), 30);

				// do not detect motion (may help reduce CPU usage)
				camera.setMotionLevel( 100 );

				ExternalInterface.addCallback('_snap', snap);
				ExternalInterface.addCallback('_configure', configure);
				ExternalInterface.addCallback('_upload', upload);
				ExternalInterface.addCallback('_reset', reset);

				if (flashvars.shutter_enabled == 1) {
					snd = new Sound();
					snd.load( new URLRequest( flashvars.shutter_url ) );
				}

				jpeg_quality = 90;

				ExternalInterface.call('webcam.flash_notify', 'flashLoadComplete', true);
            }
			else {
                trace("You need a camera.");
				ExternalInterface.call('webcam.flash_notify', "error", "No camera was detected.");
            }
        }
		
		public function set_quality(new_quality:int) {
			// set JPEG image quality
			if (new_quality < 0) new_quality = 0;
			if (new_quality > 100) new_quality = 100;
			jpeg_quality = new_quality;
		}
        
		public function configure(panel:String = SecurityPanel.CAMERA) {
			// show configure dialog inside flash movie
			Security.showSettings(panel);
		}
		
        private function activityHandler(event:ActivityEvent):void {
            trace("activityHandler: " + event);
        }
		
		public function snap(url, new_quality, shutter, new_stealth = 0) {
			// take snapshot from camera, and upload if URL was provided
			if (new_quality) set_quality(new_quality);
			stealth = new_stealth;
			trace("in snap(), drawing to bitmap");
			
			if (shutter) {
				channel = snd.play();
				setTimeout( snap2, 10, url );
			}
			else snap2(url);
		}
		
		public function snap2(url) {
			// take snapshot, convert to jpeg, submit to server
			bmpdata = new BitmapData( Math.max(video_width, server_width), Math.max(video_height, server_height) );
			bmpdata.draw( video );
			
			if (!stealth) {
				// draw snapshot on stage
				bmp = new Bitmap( bmpdata );
				addChild( bmp );
			
				// stop capturing video
				video.attachCamera( null );
				removeChild( video );
			}
			
			// if URL was provided, upload now
			if (url) upload( url );
		}
		
		public function upload(url) {
			if (bmpdata) {
				if ((video_width > server_width) && (video_height > server_height)) {
					// resize image downward before submitting
					var tmpdata = new BitmapData(server_width, server_height);
					
					var matrix = new Matrix();
					matrix.scale( server_width / video_width, server_height / video_height );
					
					tmpdata.draw( bmpdata, matrix, null, null, null, true ); // smoothing
					bmpdata = tmpdata;
				} // need resize
				
				trace("converting to jpeg");
			
				var ba:ByteArray;

				encoder = new JPGEncoder( jpeg_quality );
				ba = encoder.encode( bmpdata );
			
				trace("jpeg length: " + ba.length);
			
				var head:URLRequestHeader = new URLRequestHeader("Accept","text/*");
				var req:URLRequest = new URLRequest( url );
				req.requestHeaders.push(head);
			
				req.data = ba;
				req.method = URLRequestMethod.POST;
				req.contentType = "image/jpeg";
			
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onLoaded);
			
				trace("sending post to: " + url);
			
				try {
					loader.load(req);
				} 
				catch (error:Error) {
					trace("Unable to load requested document.");
					ExternalInterface.call('webcam.flash_notify', "error", "Unable to post data: " + error);
				}
			}
			else {
				ExternalInterface.call('webcam.flash_notify', "error", "Nothing to upload, must capture an image first.");
			}
		}
		
		public function onLoaded(evt:Event):void {
			// image upload complete
			var msg = "unknown";
			if (evt && evt.target && evt.target.data) msg = evt.target.data;
			ExternalInterface.call('webcam.flash_notify', "success", msg);
		}
		
		public function reset() {
			// reset video after taking snapshot
			if (bmp) {
				removeChild( bmp );
				bmp = null;
				bmpdata = null;
			
				video.attachCamera(camera);
            	addChild(video);
			}
		}
    }
}