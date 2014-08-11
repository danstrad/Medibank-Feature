package med.display {
	import com.greensock.easing.Quad;
	import com.greensock.TweenMax;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class ScreenSaver extends Sprite {
		
		static public const SCROLL_TIME:Number = 0.5;
		static public const SCROLL_X:Number = Main.WIDTH * 0.6;
		
		public var content:Content;

		public var overlay:ScreenSaverOverlay;
		
		protected var clickCallback:Function;

		public function ScreenSaver(title:String, content:Content, clickCallback:Function) {
			this.clickCallback = clickCallback;
			this.content = content;
			addChild(content);
			
			overlay = new ScreenSaverOverlay(title)
			overlay.x = Content.WIDTH / 2;
			overlay.y = Content.HEIGHT / 2;
			overlay.mouseEnabled = false;
			
			addChild(overlay);
			
			addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, handleRemovedFromStage, false, 0, true);
		}
		
		protected function handleAddedToStage(event:Event):void {
			//overlay.addEventListener(MouseEvent.MOUSE_DOWN, handleOverlayClick, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, handleOverlayClick, false, 0, true);
		}
		protected function handleRemovedFromStage(event:Event):void {
			//overlay.removeEventListener(MouseEvent.MOUSE_DOWN, handleOverlayClick, false);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, handleOverlayClick, false);
		}		
		protected function handleOverlayClick(event:MouseEvent):void {
			overlay.mouseEnabled = false;
			if (clickCallback != null) clickCallback();
		}
		
		public function animateOn(instant:Boolean):void {
			var homeX:Number = Content.WIDTH / 2;
			if (instant) {
				overlay.x = homeX;				
			} else {				
				overlay.x = homeX - SCROLL_X;
				TweenMax.to(overlay, SCROLL_TIME, { x:homeX, ease:Quad.easeOut } );
			}
			overlay.mouseEnabled = true;
		}
		
		public function animateOff(instant:Boolean, callback:Function):void {
			var endX:Number = Content.WIDTH / 2 + SCROLL_X;
			if (instant) {
				overlay.x = endX;
			} else {				
				TweenMax.to(overlay, SCROLL_TIME, { x:endX, ease:Quad.easeIn, onComplete:onAnimatedOff, onCompleteParams:[callback] } );
			}
		}				
		protected function onAnimatedOff(callback:Function):void {
			if (callback != null) callback();
		}
		
		
	}

}