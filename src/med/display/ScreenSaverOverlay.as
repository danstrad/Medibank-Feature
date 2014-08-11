package med.display {	import flash.display.BlendMode;	import flash.display.Graphics;	import flash.display.MovieClip;	import flash.display.Sprite;	import flash.filters.GlowFilter;	import flash.geom.Rectangle;	import flash.text.TextField;	import flash.text.TextFieldAutoSize;	import med.infographic.SplashTextSlide;	public class ScreenSaverOverlay extends Sprite {				protected var button:Sprite;		protected var prompt:MovieClip;				public function ScreenSaverOverlay(title:String) {			var scale:Number = 2.5;			scaleX = scaleY = scale;						var buttonText:String = "Touch or swipe screen to start";						var splashField:TextField = SplashTextSlide.createTextField(title, 1.1);			var maxWidth:Number = (Content.WIDTH * 0.8) / scale;			if (splashField.width > maxWidth) {				splashField.width = maxWidth;				splashField.wordWrap = true;								splashField.x = -splashField.width / 2;			}			addChild(splashField);			splashField.filters = [new GlowFilter(0xFFFFFF, 0.5, 4, 4, 1)];						button = new Sprite();			addChild(button);						button.y = splashField.getBounds(this).bottom + 50;						const ARROW_GAP:Number = 8;			const X_BORDER:Number = 15;			const Y_BORDER:Number = 10;			prompt = new _ScreenSaverText();			var textField:TextField = prompt.textField;			textField.wordWrap = false;			textField.autoSize = TextFieldAutoSize.CENTER;			textField.text = buttonText + "\n ";			var arrow:Sprite = prompt.arrow;			var promptWidth:Number = (arrow.width + ARROW_GAP + textField.width);			var promptHeight:Number = Math.abs(textField.getBounds(prompt).top) * 2;			textField.x = -promptWidth / 2;			arrow.x = promptWidth / 2 - arrow.width / 2;						var bg:Sprite = new Sprite();			var g:Graphics = bg.graphics;			g.beginFill(0xFFFFFF);			g.drawRect( -promptWidth / 2 - X_BORDER, -promptHeight / 2 - Y_BORDER, promptWidth + X_BORDER * 2, promptHeight + Y_BORDER * 2);			g.endFill();						bg.filters = [new GlowFilter(0xFFFFFF, 0.8, 12, 12, 1)];			button.addChild(bg);						prompt.blendMode = BlendMode.ERASE;			button.addChild(prompt);						button.blendMode = BlendMode.LAYER;			button.mouseChildren = false;			var bounds:Rectangle = splashField.getBounds(this).union(button.getBounds(this));			var shift:Number = -(bounds.y + bounds.height) / 2;			splashField.y = int(splashField.y + shift);			button.y = int(button.y + shift);					}			}}