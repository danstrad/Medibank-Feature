package {
	import com.greensock.easing.Quad;
	import com.greensock.TweenMax;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import med.data.BarData;
	import med.data.TextData;
	import med.data.VideoSet;
	import med.data.VideoSlide;
	import med.display.Background;
	import med.display.Content;
	import med.display.GameContent;
	import med.display.GraphContent;
	import med.display.Handle;
	import med.display.InfographicContent;
	import med.display.RateContent;
	import med.display.Screen;
	import med.display.ScreenSaver;
	import med.display.ScreenSaverOverlay;
	import med.display.StoryContent;
	import med.display.VideoContent;
	import med.infographic.InfographicData;

	public class Main extends Sprite {
		
		static public const SET_INDEX:int = 0;

		protected static const START_ON_SCREEN_SAVER:Boolean = true;

		static public const SCREEN_SAVER_IDLE_TIME:Number = 2 * 60 * 1000; // 2 minutes (in ms)
		static public const SCREEN_SAVER_WAVE_TIME_TOTAL:Number = 1600;
		static public const SCREEN_SAVER_WAVE_FLASH_TIME:Number = 0.7;
		static public const SCREEN_SAVER_WAVE_ALPHA:Number = 0.25;
		static public const SCREEN_SAVER_SCREEN_TIME:Number = 6 * 1000; // 6 seconds

		static public const HANDLE_COLOR_QUICK_CHANGE_TIME:Number = 500;
		static public const HANDLE_COLOR_CHANGE_TIME:Number = 1000;
		static public const HANDLE_ALPHA_CHANGE_TIME:Number = 300;
		static public const HANDLE_TEXT_ALPHA:Number = 0.4;
		static public const HANDLE_TEXT_CURRENT_ALPHA:Number = 0.6;

		public static const WIDTH:Number = 2857;
		public static const HEIGHT:Number = 1607;
		public static const SCALE:Number = 0.4;
		// 0.7060167387913802
		// 40% = 1143, 643

		protected var xmlLoader:URLLoader;
		protected var loadedXML:XML;
		
		protected var screenSets:Vector.<Vector.<String>>;
		protected var screenData:Dictionary;
		
		
		protected var lastFrameTime:Number;
		protected var idleTime:Number;
		protected var screenSaverMode:Boolean;
		protected var screenSaverWaveIndex:Number;
		protected var screenSaverWaveTime:Number;
		protected var screenSaverScreenTime:Number;
		protected var screenSaverScreenIndex:int;

		private var handles:Vector.<Handle>;
		
		protected var movingHandle:Handle;

		protected var dragging:Boolean;
		protected var dragPoint:Point;
		protected var dragOffset:Number; // Where on the handle was grabbed
		protected var dragFlickDistance:Number;
		protected var dragMomentum:Number;
		protected var dragTime:Number;

		protected var currentHandle:Handle;
		protected var colorSourceHandle:Handle;
		protected var handlesIdle:Boolean;
		protected var playingCurrent:Boolean;
		
		private var contentLayer:Sprite;
		private var handlesLayer:Sprite;
		

		public function Main() {
			scaleX = scaleY = 0.4;
			
			TextUtils.createTextFormats();
			new _FontDump();
			
			//soundTransform = new SoundTransform(0);
			
			handles = new Vector.<Handle>();
			
			contentLayer = new Sprite();
			addChild(contentLayer);
			handlesLayer = new Sprite();
			addChild(handlesLayer);
			
			xmlLoader = new URLLoader();
			xmlLoader.addEventListener(Event.COMPLETE, handleXMLLoaded);
			xmlLoader.load(new URLRequest("FeatureData.XML"));
			
			CONFIG::release {
				Mouse.hide();
				addEventListener(MouseEvent.CLICK, handleFullScreenClick);
			}
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, handleFullScreenChange);
		}

		protected function handleXMLLoaded(event:Event):void {
			loadedXML = new XML(xmlLoader.data);

			xmlLoader.removeEventListener(Event.COMPLETE, handleXMLLoaded);
			xmlLoader = null;

			preloadImages(loadedXML)

			addEventListener(Event.ENTER_FRAME, handleCheckImagesLoaded);
		}
		
		protected function handleCheckImagesLoaded(event:Event):void {
			if (AssetManager.isLoading) return;
			removeEventListener(Event.ENTER_FRAME, handleCheckImagesLoaded);			

			readSets(loadedXML);
			readHandles(screenSets[SET_INDEX]);
			setupHandles();
			
			lastFrameTime = getTimer();
			
			if (START_ON_SCREEN_SAVER) enterScreenSaverMode();
			idleTime = 0;
			screenSaverScreenTime = 0;
			
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
		}
		
		protected function handleMouseDown(event:MouseEvent):void {
			idleTime = 0;
			
			//if (screenSaverMode) return;
			
			var handle:Handle = event.target as Handle;
			if (!handle || !handle.draggable) return;

			movingHandle = handle;

			dragging = true;
			dragPoint = new Point(mouseX, mouseY);
			dragOffset = dragPoint.x - movingHandle.x;
			dragMomentum = 0;
			dragTime = getTimer();

			beginMovingHandle(movingHandle);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		}		
		
		protected function beginMovingHandle(handle:Handle):void {
			for each(var h:Handle in handles) {
				if ((h != handle) && !h.screen.full) {
					h.screenLeft = (h.x > handle.x);
				}
			}
			
			handle.screenLeft = handle.willBeLeft;
			showScreen(handle.screen);
			handle.showDragDirection();
			if (handle.screenLeft) {
				if (handle.prev) hideScreen(handle.prev.screen);
			} else {
				if (handle.next) hideScreen(handle.next.screen);
			}
			updateContentMasking();
			
			if (handlesIdle) {
				setHandlesIdle(false);
			}
			handle.animateColorTo(handle.homeColor, HANDLE_COLOR_QUICK_CHANGE_TIME);
			//background.fadeToColor(handle.homeColor, HANDLE_COLOR_QUICK_CHANGE_TIME);
		}
		
		protected function hideScreen(screen:Screen):void {
			if (screen.visible) {
				screen.visible = false;
				screen.resetContent();
			}
		}
		protected function showScreen(screen:Screen):void {
			if (!screen.visible) {
				screen.visible = true;
			}
		}
		
		
		protected function handleMouseMove(event:MouseEvent):void {			
			dragPoint.x = mouseX;

			var newX:Number = mouseX - dragOffset;
			var dx:Number = newX - dragPoint.x;
			
			var elapsedTime:Number = getTimer() - dragTime;
			var v:Number = 1000 * dx / (1 + elapsedTime);
			dragMomentum = 0.8 * v + 0.2 * dragMomentum;
			
			//updateMovingHandlePosition();
		}
		protected function updateMovingHandlePosition():void {
			
			if (dragging) {
				movingHandle.x = dragPoint.x - dragOffset;
				clampHandlePositions();
			}
			
			var leftBuffer:Number = handles.indexOf(movingHandle) * Handle.WIDTH;
			
			var onRight:Boolean = (movingHandle.x > leftBuffer + ((WIDTH - Handle.WIDTH) / 2));
			var crossed:Boolean = onRight == movingHandle.left;
			if (crossed) {
				if (movingHandle != colorSourceHandle) {
					broadcastHandleColor(movingHandle, HANDLE_COLOR_CHANGE_TIME);
				}
			} else {
				if (currentHandle != colorSourceHandle) {
					broadcastHandleColor(currentHandle, HANDLE_COLOR_CHANGE_TIME);
					movingHandle.animateColorTo(movingHandle.homeColor, HANDLE_COLOR_QUICK_CHANGE_TIME);
				}
			}
			
		}	

		protected function handleMouseUp(event:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			
			dragging = false;
			const weight:Number = 1;//0.8;
			dragFlickDistance = dragMomentum * weight;
			dragPoint.x = movingHandle.x;
			dragTime = getTimer();
			
			var leftBuffer:Number = handles.indexOf(movingHandle) * Handle.WIDTH;
			
			const DRAG_REQUIRED:Number = 0.1;
			var dragF:Number = (movingHandle.left) ? DRAG_REQUIRED : (1 - DRAG_REQUIRED);
			var dragCutoff:Number = leftBuffer + Content.WIDTH * dragF - Handle.WIDTH / 2;
			
			var suckRight:Boolean = (movingHandle.x + dragFlickDistance) > dragCutoff;
			suckHandle(movingHandle, suckRight);

			movingHandle.clearDragDirection();
			movingHandle = null;
		}
		
		protected function suckHandle(handle:Handle, suckRight:Boolean):void {
			var h:Handle;
			if (handle) {
				//var suckRight:Boolean = (handle.x > (WIDTH - Handle.WIDTH) / 2);
				if (suckRight) {
					if (handle.left) {
						handle.homeX = WIDTH - Handle.WIDTH - handle.nextCount * Handle.WIDTH;
						handle.willBeLeft = false;
						for (h = handle.next; h != null; h = h.next) {
							h.homeX = WIDTH - Handle.WIDTH - h.nextCount * Handle.WIDTH;
							h.willBeLeft = false;
						}
					}
				} else {
					if (!handle.left) {
						handle.homeX = handle.prevCount * Handle.WIDTH;
						handle.willBeLeft = true;
						for (h = handle.prev; h != null; h = h.prev) {
							h.homeX = h.prevCount * Handle.WIDTH;
							h.willBeLeft = true;
						}
					}
				}
			}
			
			if (handle.left != handle.willBeLeft) {
				for each(h in handles) {
					h.draggable = (h != handle);
				}
			}

		}
		
		
		protected function handleEnterFrame(event:Event):void {
			var time:Number = getTimer();
			var dTime:Number = time - lastFrameTime;
			
			lastFrameTime = time;
			
			animate(dTime);
			
			for each(var h:Handle in handles) h.animate(dTime);
		}
		
		protected function animate(dTime:Number):void {
			//background.animate(dTime);
			
			if (screenSaverMode) {
				// continue the flashing handle wave
				screenSaverWaveTime += dTime;
				var waveTime:Number = SCREEN_SAVER_WAVE_TIME_TOTAL / handles.length;
				if (screenSaverWaveTime >= waveTime) {
					screenSaverWaveTime -= waveTime;
					screenSaverWaveIndex = (screenSaverWaveIndex + 1) % handles.length;
					var waveHandle:Handle = handles[screenSaverWaveIndex];
					if (waveHandle == currentHandle) {
						screenSaverWaveIndex = (screenSaverWaveIndex + 1) % handles.length;
						waveHandle = handles[screenSaverWaveIndex];
					}
					var flashTime:Number = SCREEN_SAVER_WAVE_FLASH_TIME;
					TweenMax.to(waveHandle.idleFlasher, flashTime, { alpha:SCREEN_SAVER_WAVE_ALPHA, ease:Quad.easeOut } );
					TweenMax.to(waveHandle.idleFlasher, flashTime, { alpha:0, delay:flashTime, ease:Quad.easeIn } );
				}
				screenSaverScreenTime += dTime;
				if (screenSaverScreenTime >= SCREEN_SAVER_SCREEN_TIME) {
					screenSaverScreenTime -= SCREEN_SAVER_SCREEN_TIME;
					nextScreenSaverScreen();
				}
			} else {
				// Check if enough idleTime has passed to enter screenSaverMode
				if (currentHandle) {
					//if (currentHandle && currentHandle.screen.content.isIdle) {
					if (currentHandle.screen.content.takenAction) {
						currentHandle.screen.content.takenAction = false;
						idleTime = 0;
					} else {
						idleTime += dTime;
						if (idleTime > SCREEN_SAVER_IDLE_TIME) {
							idleTime = 0;
							enterScreenSaverMode();
						}
					}
				} else {
					idleTime = 0;
				}
			}

			if (movingHandle) updateMovingHandlePosition();
						
			clampHandlePositions();
			var snapF:Number = (dragging) ? 1 : 0.3;
			for each(var handle:Handle in handles) {
				if (dragging && (handle == movingHandle)) continue;
				handle.x = handle.x + (handle.homeX - handle.x) * snapF;
				var MOVE:Number = 3;
				if (handle.x > handle.homeX) handle.x = Math.max(handle.x - MOVE, handle.homeX);
				else handle.x = Math.min(handle.x + MOVE, handle.homeX);
			}
			clampHandlePositions();
			
			// Reached desinations?
			var allAtHome:Boolean = !dragging;
			for each(handle in handles) {
				if (dragging && (handle == movingHandle)) continue;
				if (Math.abs(handle.x - handle.homeX) <= 1) {
					handle.x = handle.homeX;
					handle.left = handle.willBeLeft;
					if (handle == movingHandle) {
						movingHandle.clearDragDirection();
						movingHandle = null;
					}					
				} else {
					allAtHome = false;
				}
			}
			
			updateContentMasking();			
			
			if (allAtHome) {
				for each (var h:Handle in handles) {
					if (h.screen.full) {
						if (h != currentHandle) {
							currentHandle = h;
						}
					}
				}			
			
				if (!handlesIdle) {
					setHandlesIdle(true);
					broadcastHandleColor(currentHandle, HANDLE_COLOR_CHANGE_TIME);
				}
			}

			if (currentHandle && currentHandle.screen.full) {
				if (!playingCurrent) {
					TweenMax.resumeAll();
					currentHandle.screen.resumeContent();
					playingCurrent = true;
				}
				currentHandle.screen.animateContent(dTime);
			} else {
				if (playingCurrent) {
					TweenMax.pauseAll();
					currentHandle.screen.pauseContent();
					playingCurrent = false;
				}
			}

			for each(h in handles) {
				if (!h.screen.closed && h.screen.visible) {
					h.screen.animateScreenSaver(dTime);
				}
			}
			
		}
		
		protected function clampHandlePositions():void {			
			if (movingHandle) {
				var h:Handle;
				// Push left from handle
				for (h = movingHandle.prev; h != null; h = h.prev) {
					h.x = Math.min(h.x, h.next.x - Handle.WIDTH);
				}
				// Push right from handle
				for (h = movingHandle.next; h != null; h = h.next) {
					h.x = Math.max(h.x, h.prev.x + Handle.WIDTH);
				}
			}
			// Push right from edge
			for (h = handles[0]; h != null; h = h.next) {
				h.x = Math.max(h.x, rightEdgeOfPrev(h));
			}
			// Push left from edge				
			for (h = handles[handles.length - 1]; h != null; h = h.prev) {
				h.x = Math.min(h.x, leftEdgeOfNext(h) - Handle.WIDTH);
			}
		}
		
		protected function updateContentMasking():void {
			for each (var h:Handle in handles) {
				//if (!h.content.visible) continue;
				
				if (h.screenLeft) {
					showScreenBetween(rightEdgeOfPrev(h), h.x, h.screen);
				} else {
					showScreenBetween(h.x + Handle.WIDTH, leftEdgeOfNext(h), h.screen);
				}
				
				//if (!h.content.closed) showContent(h.content);
				
				if (!movingHandle) {
					if (h.screen.closed) {
						hideScreen(h.screen);
					}
				}
			}
		}
		
		protected function rightEdgeOfPrev(h:Handle):Number {
			var p:Handle = h.prev;
			if (p) return p.x + Handle.WIDTH;
			else return 0;
		}
		protected function leftEdgeOfNext(h:Handle):Number {
			var n:Handle = h.next;
			if (n) return n.x;
			else return WIDTH;
		}
		
		protected function showScreenBetween(l:Number, r:Number, screen:Screen):void {
			screen.x = l;
			//screen.full = ((r - l) >= (Content.WIDTH - 1)) && screen.visible;
			screen.full = ((r - l) >= (Content.WIDTH * 0.98)) && screen.visible;
			
			if (r - l >= 1) {
				screen.closed = false;
				var w:Number = Math.ceil(r - l) + 1;
				var x:Number = Math.ceil((Content.WIDTH - (r - l)) / 2);
				screen.scrollRect = new Rectangle(x, 0, w, HEIGHT);
			} else {
				if (!screen.closed) {
					if (screen.screenSaver.visible) screen.resetScreenSaver();
				}
				screen.closed = true;
			}
		}
		
		protected function broadcastHandleColor(source:Handle, time:Number):void {			
			colorSourceHandle = source;
			var len:int = handles.length;
			var index:int = handles.indexOf(source);
			var maxAway:int = Math.max(index, len - index - 1);
			var step:Number = 1 / maxAway;
			var current:Number;
			var h:Handle;
			var color:uint;

			source.animateColorTo(source.homeColor, time);
			
			current = 0;
			for (h = source.prev; h != null; h = h.prev) {
				current += step;
				color = adjustColor(source.homeColor, current);
				h.animateColorTo(color, time);
			}
			
			current = 0;
			for (h = source.next; h != null; h = h.next) {
				current += step;
				color = adjustColor(source.homeColor, current);
				h.animateColorTo(color, time);
			}
			
		}
		
		protected function setHandlesIdle(value:Boolean):void {
			if (handlesIdle == value) return;
			handlesIdle = value;
			for each(var h:Handle in handles) {
				var alpha:Number;
				if (value) {
					if (h == currentHandle) alpha = HANDLE_TEXT_CURRENT_ALPHA;
					else alpha = HANDLE_TEXT_ALPHA;
				} else {
					alpha = 1;
				}
				h.animateAlphaTo(alpha, HANDLE_ALPHA_CHANGE_TIME);
			}
		}
		
		
		protected function adjustColor(sourceColor:uint, offsetF:Number):uint {
			var channelIncrease:Number = offsetF * 50;
			var r:uint = Math.min(0xFF, uint(((sourceColor & 0xFF0000) >> 16) + channelIncrease)) << 16;
			var g:uint = Math.min(0xFF, uint(((sourceColor & 0xFF00) >> 8) + channelIncrease)) << 8;
			var b:uint = Math.min(0xFF, uint(((sourceColor & 0xFF)) + channelIncrease));
			return r + g + b;
		}

		
		
		
		protected function nextScreenSaverScreen():void {
			var currentIndex:int = screenSaverScreenIndex;
			screenSaverScreenIndex = (screenSaverScreenIndex + 1) % handles.length;
			var handle:Handle = handles[screenSaverScreenIndex];
			if (!handle.draggable) return;
			movingHandle = handle;
			beginMovingHandle(handle);
			suckHandle(handle, (screenSaverScreenIndex < currentIndex));
		}
		
		
		protected function enterScreenSaverMode():void {
			screenSaverWaveIndex = -1;
			screenSaverWaveTime = 0;
			screenSaverMode = true;
			for each(var h:Handle in handles) {
				var instant:Boolean = (h != currentHandle);
				h.screen.fadeToScreenSaver(instant);
			}
			screenSaverScreenIndex = handles.indexOf(currentHandle);
			
		}
		
		protected function onScreenSaverFinished():void {
			screenSaverMode = false;
			for each(var h:Handle in handles) {
				var instant:Boolean = (h != currentHandle);
				h.screen.fadeToContent(instant);
			}
		}
		
		
		
		
		
		
		
		
		
		
		
		static public function preloadImages(loadedXML:XML):void {
			//<Image url="assets/Test Image.png" />
			var xmlString:String = loadedXML.toString();
			for (var index:int = xmlString.lastIndexOf("<Image"); index >= 0; index = xmlString.lastIndexOf("<Image", index - 1)) {
				var startIndex:int = xmlString.indexOf("\"", index);
				var endIndex:int = xmlString.indexOf("\"", startIndex + 1);
				var url:String = xmlString.substr(startIndex + 1, (endIndex - startIndex) - 1);
				AssetManager.loadImage(url);
			}			
		}
				
		protected function readSets(loadedXML:XML):void {
			screenSets = new Vector.<Vector.<String>>();
			var id:String;
			for each(var setXML:XML in loadedXML.ScreenSet) {
				var screenSet:Vector.<String> = new Vector.<String>();
				var s:String = setXML.toString();
				s = s.replace(/ /ig, "");
				var ids:Array = s.split(",");
				for each(id in ids) screenSet.push(id);
				screenSets.push(screenSet);
			}
			screenData = new Dictionary();
			for each(var screenXML:XML in loadedXML.Screen) {
				id = screenXML.@id.toString();
				screenData[id] = screenXML;
			}
		}
		
		protected function readHandles(screenSet:Vector.<String>):void {
			Handle.WIDTH = Handle.TOTAL_WIDTH / screenSet.length;
			for each(var id:String in screenSet) {
				var screenXML:XML = screenData[id];
				
				// Color
				var color:uint;
				if (screenXML.hasOwnProperty("Colour")) {
					var colorString:String = screenXML.Colour[0].toString();
					if (colorString.charAt(0) == "#") colorString = colorString.substr(1);
					color = uint("0x" + colorString);
				} else {
					switch(handles.length) {
						default:
						case 0: color = 0x1B75BB; break;
						case 1: color = 0xF69220; break;
						case 2: color = 0xEA2B8B; break;
						case 3: color = 0xED4135; break;
					}
				}
				
				// Handle Text
				var handleText:String = "";
				if (screenXML.hasOwnProperty("Handle")) handleText = screenXML.Handle[0].toString();				
				var screenSaverText:String = handleText;
				
				var content:Content = null;
				if (screenXML.hasOwnProperty("Content")) content = createContent(screenXML.Content[0], color);
				if (!content) content = new Content(color);				
				var screenSaverContent:Content = null;
				if (screenXML.hasOwnProperty("ScreenSaverContent")) {
					screenSaverContent = createContent(screenXML.ScreenSaverContent[0], color);
					var screenSaverXML:XML = screenXML.ScreenSaverContent[0];
					if (screenSaverXML.hasOwnProperty("@alpha")) {
						if (screenSaverContent) screenSaverContent.alpha = parseFloat(screenSaverXML.@alpha);
					}
					if (screenSaverXML.hasOwnProperty("ScreenSaverText")) screenSaverText = TextUtils.safeText(screenSaverXML.ScreenSaverText[0].toString());
				}
				if (!screenSaverContent) screenSaverContent = new Content(color);
				
				
				var screen:Screen = new Screen(handleText, color, content, screenSaverContent, screenSaverText, onScreenSaverFinished);
				
				handles.push(new Handle(handleText, screen));
			}
				
		}
		
		protected static function createContent(xml:XML, color:uint):Content {
			var title:String;
			var title1:String;
			var title2:String;
			var text:String;
			var graphText:String;
			
			var content:Content;
			switch(xml.@type.toString().toLowerCase()) {
				case "pong":
					title1 = "";
					title2 = "";
					if (xml.hasOwnProperty("Title1")) title1 = xml.Title1.toString();
					if (xml.hasOwnProperty("Title2")) title2 = xml.Title2.toString();
					content = new GameContent(color, title1, title2);
					break;
					
				case "graph":
					title = "";
					text = "";
					graphText = "";
					var bars:Vector.<BarData> = new Vector.<BarData>();
					if (xml.hasOwnProperty("Title")) title = xml.Title.toString();
					if (xml.hasOwnProperty("Text")) text = xml.Text.toString();
					if (xml.hasOwnProperty("Graph")) {
						var graphXML:XML = xml.Graph[0];
						if (graphXML.hasOwnProperty("Text")) graphText = graphXML.Text.toString();
						for each(var barXML:XML in graphXML.Bar) {
							bars.push(new BarData(parseFloat(barXML.@value) || 1, barXML.@text.toString() || ""));
						}
					}
					content = new GraphContent(color, title, text, graphText, bars);
					break;
					
				case "rate":
					title = "";
					if (xml.hasOwnProperty("Title")) title = xml.Title.toString();
					var labels:Vector.<String> = new Vector.<String>();
					if (xml.hasOwnProperty("Label0")) labels.push(xml.Label0.toString());
					else labels.push("");
					if (xml.hasOwnProperty("Label50")) labels.push(xml.Label50.toString());
					else labels.push("");
					if (xml.hasOwnProperty("Label100")) labels.push(xml.Label100.toString());
					else labels.push("");
					content = new RateContent(color, title, labels);
					break;
					
				case "video":
					var sets:Vector.<VideoSet> = new Vector.<VideoSet>();
					for each(var setXML:XML in xml.Set) {
						var videoSet:VideoSet = new VideoSet();
						for each(var slideXML:XML in setXML.Video) {
							var slide:VideoSlide = new VideoSlide();
							if (slideXML.hasOwnProperty("@url")) slide.url = slideXML.@url.toString();
							else continue;
							if (slideXML.hasOwnProperty("@width")) slide.width = parseFloat(slideXML.@width);
							else slide.width = 1920;
							if (slideXML.hasOwnProperty("@height")) slide.height = parseFloat(slideXML.@height);
							else slide.height = 1088;
							if (slideXML.hasOwnProperty("Title")) slide.title = slideXML.Title[0].toString();
							if (slideXML.hasOwnProperty("Text")) slide.text = slideXML.Text[0].toString();
							videoSet.slides.push(slide);
						}
						sets.push(videoSet);
					}
					content = new VideoContent(color, sets);
					break;
					
				case "story":
					var datas:Vector.<TextData> = new Vector.<TextData>();
					for each(var textXML:XML in xml.Text) {
						datas.push(new TextData(textXML.@type.toString(), textXML.toString()));
					}
					var bgImage:BitmapData;
					if (xml.hasOwnProperty("Background")) {
						var backgroundXML:XML = xml.Background[0];
						if (backgroundXML.hasOwnProperty("Image")) {
							var imageXML:XML = backgroundXML.Image[0];
							bgImage = AssetManager.getImage(imageXML.@url.toString());
						}
					}
					content = new StoryContent(color, datas, bgImage);
					break;
					
				case "infographic":
					var infographicXML:XML = xml.Infographic[0];
					content = new InfographicContent(color, new InfographicData(infographicXML));
					break;
			}
			return content;
		}
		
		protected function setupHandles():void {
			var prev:Handle = null;
			for (var i:int = 0; i < handles.length; i++) {
				var handle:Handle = handles[i];
				handle.prev = prev;
				if (prev) prev.next = handle;
				prev = handle;
				handle.prevCount = i;
				handle.nextCount = handles.length - i - 1;
				handlesLayer.addChildAt(handle, 0);
				handle.x = handle.homeX = i * Handle.WIDTH;
				handle.left = handle.willBeLeft = true;
				handle.screen.pauseContent()
				if (i == handles.length - 1) {
					handle.draggable = false;
					handle.screenLeft = false;
					handle.screen.visible = true;
					broadcastHandleColor(handle, 0);
					currentHandle = handle;
				} else {
					handle.draggable = true;
					handle.screenLeft = true;
					handle.screen.visible = false;
				}
				contentLayer.addChild(handle.screen);
			}
			clampHandlePositions();
			updateContentMasking();
		}
		
		protected function handleFullScreenClick(event:MouseEvent):void {
			stage.displayState = StageDisplayState.FULL_SCREEN;
			removeEventListener(MouseEvent.CLICK, handleFullScreenClick);
		}
		protected function handleFullScreenChange(event:FullScreenEvent):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				addEventListener(MouseEvent.CLICK, handleFullScreenClick);
			}
		}
	}

}