package {
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import med.data.BarData;
	import med.data.TextData;
	import med.data.VideoSet;
	import med.data.VideoSlide;
	import med.display.Content;
	import med.display.GameContent;
	import med.display.GraphContent;
	import med.display.Handle;
	import med.display.InfographicContent;
	import med.display.RateContent;
	import med.display.StoryContent;
	import med.display.VideoContent;
	import med.infographic.InfographicData;

	public class Main extends Sprite {

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

		private var handles:Vector.<Handle>;
		
		protected var dragging:Boolean;
		protected var dragHandle:Handle;
		protected var dragPoint:Point;
		protected var dragFlickDistance:Number;
		protected var dragMomentum:Number;
		protected var dragTime:Number;

		protected var currentContent:Content;
		
		private var contentLayer:Sprite;
		private var handlesLayer:Sprite;

		public function Main() {
			scaleX = scaleY = 0.4;
			
			TextUtils.createTextFormats();
			new _FontDump();
			
			handles = new Vector.<Handle>();
			
			contentLayer = new Sprite();
			addChild(contentLayer);
			handlesLayer = new Sprite();
			addChild(handlesLayer);
			
			xmlLoader = new URLLoader();
			xmlLoader.addEventListener(Event.COMPLETE, handleXMLLoaded);
			xmlLoader.load(new URLRequest("FeatureData.XML"));
			
			CONFIG::release {
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
			readHandles(screenSets[0]);
			setupHandles();
			
			lastFrameTime = getTimer();
			
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
		}
		
		protected function handleMouseDown(event:MouseEvent):void {
			var handle:Handle = event.target as Handle;
			if (!handle || !handle.draggable) return;

			dragging = true;
			dragHandle = handle;
			dragPoint = new Point(mouseX, mouseY);
			dragMomentum = 0;
			dragTime = getTimer();

			handle.contentLeft = handle.willBeLeft;// left;
			handle.content.visible = true;
			handle.showDragDirection();
			if (handle.contentLeft) {
				if (handle.prev) handle.prev.content.visible = false;				
			} else {
				if (handle.next) handle.next.content.visible = false;
			}
			updateContentMasking();
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
		}		
		
		protected function handleMouseMove(event:MouseEvent):void {
			var dx:Number = mouseX - dragPoint.x;
			dragPoint.x = mouseX;
			//dragHandle.x = mouseX - Handle.WIDTH / 2;
			
			var elapsedTime:Number = getTimer() - dragTime;
			var v:Number = 1000 * dx / (1 + elapsedTime);
			dragMomentum = 0.8 * v + 0.2 * dragMomentum;
			
			dragHandle.x += dx;
			clampHandlePositions();
			updateContentMasking();
		}	

		protected function handleMouseUp(event:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);

			dragHandle.clearDragDirection();
			
			dragging = false;
			const weight:Number = 1;//0.8;
			dragFlickDistance = dragMomentum * weight;
			dragPoint.x = dragHandle.x;
			dragTime = getTimer();
			
			var suckRight:Boolean = (dragHandle.x + dragFlickDistance) > (WIDTH - Handle.WIDTH) / 2;
			elasticizeDragHandle(dragHandle, suckRight);

			dragHandle = null;
		}
		
		protected function elasticizeDragHandle(handle:Handle, suckRight:Boolean):void {
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

			clampHandlePositions();
			updateContentMasking();
		}
		
		
		protected function handleEnterFrame(event:Event):void {
			var time:Number = getTimer();
			var dTime:Number = time - lastFrameTime;
			
			lastFrameTime = time;
			
			animate(dTime);
		}
		
		protected function animate(dTime:Number):void {
			clampHandlePositions();	
			for each(var handle:Handle in handles) {
				if (handle == dragHandle) continue;
				handle.x = handle.x + (handle.homeX - handle.x) * 0.3;
				var MOVE:Number = 3;
				if (handle.x > handle.homeX) handle.x = Math.max(handle.x - MOVE, handle.homeX);
				else handle.x = Math.min(handle.x + MOVE, handle.homeX);
			}
			clampHandlePositions();
			// Reached desinations?
			for each(handle in handles) {
				if (handle == dragHandle) continue;
				if (Math.abs(handle.x - handle.homeX) <= 1) {
					handle.x = handle.homeX;
					handle.left = handle.willBeLeft;
				}
			}
			updateContentMasking();
			
			for each(handle in handles) {
				if (handle.content.visible) {
					handle.content.animate(dTime);
				}
				//handle.draggable = (handle.content != currentContent);
			}
		}
		
		protected function clampHandlePositions():void {			
			if (dragHandle) {
				var h:Handle;
				// Push left from handle
				for (h = dragHandle.prev; h != null; h = h.prev) {
					h.x = Math.min(h.x, h.next.x - Handle.WIDTH);
				}
				// Push right from handle
				for (h = dragHandle.next; h != null; h = h.next) {
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
				if (!h.content.visible) continue;
				
				if (h.contentLeft) {
					showContentBetween(rightEdgeOfPrev(h), h.x, h.content);
				} else {
					showContentBetween(h.x + Handle.WIDTH, leftEdgeOfNext(h), h.content);
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
		
		protected function showContentBetween(l:Number, r:Number, content:Content):void {
			content.x = l;

			content.scrollRect = new Rectangle(0, 0, Math.ceil(r - l), HEIGHT);
			/*
			if ((r - l) >= 1) {
				content.visible = true;
				content.scrollRect = new Rectangle(0, 0, Math.ceil(r - l), HEIGHT);
			} else {
				content.visible = false;
			}
			*/
			
			content.full = ((r - l) >= (Content.WIDTH - 1));
			if (content.full) currentContent = content;
		}
		
		protected function broadcastHandleColor(source:Handle, time:Number):void {
			source.animateColor(source.homeColor, time);			
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
						case 0: color = 0x1B75BB; break;
						case 1: color = 0xF69220; break;
						case 2: color = 0xEA2B8B; break;
						case 3: color = 0xED4135; break;
					}
				}
				
				// Handle Text
				var handleText:String = "";
				if (screenXML.hasOwnProperty("Handle")) handleText = screenXML.Handle[0].toString();
				
				// Type
				var title:String;
				var title1:String;
				var title2:String;
				var text:String;
				var graphText:String;
				
				var content:Content;
				switch(screenXML.@type.toString().toLowerCase()) {
					case "pong":
						title1 = "";
						title2 = "";
						if (screenXML.hasOwnProperty("Title1")) title1 = screenXML.Title1.toString();
						if (screenXML.hasOwnProperty("Title2")) title2 = screenXML.Title2.toString();
						content = new GameContent(color, title1, title2);
						break;
						
					case "graph":
						title = "";
						text = "";
						graphText = "";
						var bars:Vector.<BarData> = new Vector.<BarData>();
						if (screenXML.hasOwnProperty("Title")) title = screenXML.Title.toString();
						if (screenXML.hasOwnProperty("Text")) text = screenXML.Text.toString();
						if (screenXML.hasOwnProperty("Graph")) {
							var graphXML:XML = screenXML.Graph[0];
							if (graphXML.hasOwnProperty("Text")) graphText = graphXML.Text.toString();
							for each(var barXML:XML in graphXML.Bar) {
								bars.push(new BarData(parseFloat(barXML.@value) || 1, barXML.@text.toString() || ""));
							}
						}
						content = new GraphContent(color, title, text, graphText, bars);
						break;
						
					case "rate":
						title = "";
						if (screenXML.hasOwnProperty("Title")) title = screenXML.Title.toString();
						var labels:Vector.<String> = new Vector.<String>();
						if (screenXML.hasOwnProperty("Label0")) labels.push(screenXML.Label0.toString());
						else labels.push("");
						if (screenXML.hasOwnProperty("Label50")) labels.push(screenXML.Label50.toString());
						else labels.push("");
						if (screenXML.hasOwnProperty("Label100")) labels.push(screenXML.Label100.toString());
						else labels.push("");
						content = new RateContent(color, title, labels);
						break;
						
					case "video":
						var sets:Vector.<VideoSet> = new Vector.<VideoSet>();
						for each(var setXML:XML in screenXML.Set) {
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
						for each(var textXML:XML in screenXML.Text) {
							datas.push(new TextData(textXML.@type.toString(), textXML.toString()));
						}
						var bgImage:BitmapData;
						if (screenXML.hasOwnProperty("Background")) {
							var backgroundXML:XML = screenXML.Background[0];
							if (backgroundXML.hasOwnProperty("Image")) {
								var imageXML:XML = backgroundXML.Image[0];
								bgImage = AssetManager.getImage(imageXML.@url.toString());
							}
						}
						content = new StoryContent(color, datas, bgImage);
						break;
						
					case "infographic":
						var infographicXML:XML = screenXML.Infographic[0];
						content = new InfographicContent(color, new InfographicData(infographicXML));
						break;
				}				
				handles.push(new Handle(handleText, content));
			}
				
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
				if (i == handles.length - 1) {
					handle.draggable = false;
					handle.contentLeft = false;
					handle.content.visible = true;
					broadcastHandleColor(handle, 0);
				} else {
					handle.draggable = true;
					handle.contentLeft = true;
					handle.content.visible = false;
				}
				contentLayer.addChild(handle.content);
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