package med.display {
	import med.infographic.Infographic;
	import med.infographic.InfographicData;

	public class InfographicContent extends Content {
		
		protected var infographicData:InfographicData;

		protected var infographic:Infographic;
		
		/*
		 * Default Infographic size is 1024 x 576
		 * 
		 * Window size for Content is 2857 - 399 x 1607 (2458 x 1607)
		 * 
		 * Infographic scaling to map default size to the window (with letterboxing) = 2.400390625
		 * Unscaled height including letterboxing = 669.4743694060212
		 * 
		 * scale of a 1080 video = 0.6198836753759455
		 * scale of a 1088 video = 0.6153257071746518
		 */
		
		public function InfographicContent(color:uint, infographicData:InfographicData) {
			Infographic.HEIGHT = 670;

			super(color);
			this.infographicData = infographicData;
			
			var colors:Vector.<uint> = new Vector.<uint>();
			
			infographic = new Infographic(infographicData, background, colors);
			addChild(infographic);
			infographic.x = WIDTH / 2;
			infographic.y = HEIGHT / 2;
			var scale:Number = Math.min(WIDTH / 1024, HEIGHT / 576);
			infographic.scaleX = infographic.scaleY = scale;
			
		}
		
		override public function animate(dTime:Number):void {
			super.animate(dTime);
			
			infographic.animate(dTime);
		}

	}

}