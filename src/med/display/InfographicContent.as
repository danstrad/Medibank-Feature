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
			
			var infographicColors:Vector.<uint> = new Vector.<uint>();
			
			if (infographicData.xml.hasOwnProperty("InfographicColors")) {
				// get the colors from a tag at the infographic level (rather than at Chapter level in Medibank-Core)
				infographicColors.push(uint(infographicData.xml.InfographicColors.@color1.toString().replace("#", "0x")));
				infographicColors.push(uint(infographicData.xml.InfographicColors.@color2.toString().replace("#", "0x")));
				infographicColors.push(uint(infographicData.xml.InfographicColors.@color3.toString().replace("#", "0x")));			
			} else {
				// default colors for fallback (red/vision)
				infographicColors.push(0xe4002b);
				infographicColors.push(0xFFFFFF);
				infographicColors.push(0xEC4D6B);				
			}			
			
			infographic = new Infographic(infographicData, background, infographicColors);
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