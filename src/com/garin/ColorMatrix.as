﻿/**
* original ColorMatrix by Grant Skinner. August 8, 2005
* Visit www.gskinner.com/blog for documentation, updates and more free code.
*/

package com.garin {	
	
	public class ColorMatrix {
	
		private var matrix:Array;
		
		// constant for contrast calculations:
		private static var DELTA_INDEX:Array = [
			0,    0.01, 0.02, 0.04, 0.05, 0.06, 0.07, 0.08, 0.1,  0.11,
			0.12, 0.14, 0.15, 0.16, 0.17, 0.18, 0.20, 0.21, 0.22, 0.24,
			0.25, 0.27, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40, 0.42,
			0.44, 0.46, 0.48, 0.5,  0.53, 0.56, 0.59, 0.62, 0.65, 0.68, 
			0.71, 0.74, 0.77, 0.80, 0.83, 0.86, 0.89, 0.92, 0.95, 0.98,
			1.0,  1.06, 1.12, 1.18, 1.24, 1.30, 1.36, 1.42, 1.48, 1.54,
			1.60, 1.66, 1.72, 1.78, 1.84, 1.90, 1.96, 2.0,  2.12, 2.25, 
			2.37, 2.50, 2.62, 2.75, 2.87, 3.0,  3.2,  3.4,  3.6,  3.8,
			4.0,  4.3,  4.7,  4.9,  5.0,  5.5,  6.0,  6.5,  6.8,  7.0,
			7.3,  7.5,  7.8,  8.0,  8.4,  8.7,  9.0,  9.4,  9.6,  9.8, 
			10.0
		]
	
		// identity matrix constant:
		private static var IDENTITY_MATRIX:Array = [
			1,0,0,0,0,
			0,1,0,0,0,
			0,0,1,0,0,
			0,0,0,1,0,
			0,0,0,0,1
		]
		private static var LENGTH:Number = IDENTITY_MATRIX.length;
		
	
		// initialization:
		public function ColorMatrix(p_brightness:Number = 0, p_contrast:Number = 0, p_saturation:Number = 0, p_hue:Number = 0) {
			set_values(p_brightness, p_contrast, p_saturation, p_hue);
		}
	
		public function set_values(pb : Number, pc : Number, ps : Number, ph : Number):void {
			// this is to help avoid thousands of per-frame memory allocations which annoy the garbage collector 
			// however, this is still quite expensive math-wise and shouldn't get called every frame if possible - andrew			
			matrix = IDENTITY_MATRIX.concat();
			adjustColor(pb, pc, ps, ph);
		}
		
	
	// public methods:
	
		public function adjustColor(p_brightness:Number,p_contrast:Number,p_saturation:Number,p_hue:Number):void {
			adjustHue(p_hue);
			adjustContrast(p_contrast);
			adjustBrightness(p_brightness);
			adjustSaturation(p_saturation);
		}

		public function adjustBrightness(p_val:Number):void {
			p_val = cleanValue(p_val,100);
			if (p_val == 0) { return; }
			multiplyMatrix([
				1,0,0,0,p_val,
				0,1,0,0,p_val,
				0,0,1,0,p_val,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustContrast(p_val:Number):void {
			p_val = cleanValue(p_val,100);
			if (p_val == 0) { return; }
			var x:Number;
			if (p_val<0) {
				x = 127+p_val/100*127
			} else {
				x = p_val%1;
				if (x == 0) {
					x = DELTA_INDEX[p_val];
				} else {
					//x = DELTA_INDEX[(p_val<<0)]; // matrix is how the IDE does it.
					x = DELTA_INDEX[(p_val<<0)]*(1-x)+DELTA_INDEX[(p_val<<0)+1]*x; // use linear interpolation for more granularity.
				}
				x = x*127+127;
			}
			multiplyMatrix([
				x/127,0,0,0,0.5*(127-x),
				0,x/127,0,0,0.5*(127-x),
				0,0,x/127,0,0.5*(127-x),
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustSaturation(p_val:Number):void {
			p_val = cleanValue(p_val,100);
			if (p_val == 0) { return; }
			var x:Number = 1+((p_val > 0) ? 3*p_val/100 : p_val/100);
			var lumR:Number = 0.3086;
			var lumG:Number = 0.6094;
			var lumB:Number = 0.0820;
			multiplyMatrix([
				lumR*(1-x)+x,lumG*(1-x),lumB*(1-x),0,0,
				lumR*(1-x),lumG*(1-x)+x,lumB*(1-x),0,0,
				lumR*(1-x),lumG*(1-x),lumB*(1-x)+x,0,0,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
	
		public function adjustHue(p_val:Number):void {
			
			p_val *= (Math.PI / 180);
			var cosVal:Number = Math.cos(p_val);
			var sinVal:Number = Math.sin(p_val);
			var lumR:Number = 0.213;
			var lumG:Number = 0.715;
			var lumB:Number = 0.072;
			multiplyMatrix([
				lumR+cosVal*(1-lumR)+sinVal*(-lumR),lumG+cosVal*(-lumG)+sinVal*(-lumG),lumB+cosVal*(-lumB)+sinVal*(1-lumB),0,0,
				lumR+cosVal*(-lumR)+sinVal*(0.143),lumG+cosVal*(1-lumG)+sinVal*(0.140),lumB+cosVal*(-lumB)+sinVal*(-0.283),0,0,
				lumR+cosVal*(-lumR)+sinVal*(-(1-lumR)),lumG+cosVal*(-lumG)+sinVal*(lumG),lumB+cosVal*(1-lumB)+sinVal*(lumB),0,0,
				0,0,0,1,0,
				0,0,0,0,1
			]);
		}
		
		public function toString():String {
			return "ColorMatrix [ "+matrix.join(" , ")+" ]";
		}
	
		// return a length 20 array (5x4):
		public function toArray():Array {
			return matrix.slice(0,20);
		}
		
	// private methods:
		
		// multiplies one matrix against another:
		private function multiplyMatrix(p_matrix:Array):void {
			var col:Array = [];
			
			var i:int, j:int, k:int;
			
			for (i=0;i<5;i++) {
				for (j=0;j<5;j++) {
					col[j] = matrix[j+i*5];
				}
				for (j=0;j<5;j++) {
					var val:Number=0;
					for (k=0;k<5;k++) {
						val += p_matrix[j+k*5]*col[k];
					}
					matrix[j+i*5] = val;
				}
			}
		}
		
		// make sure values are within the specified range, hue has a limit of 180, others are 100:
		private function cleanValue(p_val:Number,p_limit:Number):Number {
			return Math.min(p_limit,Math.max(-p_limit,p_val));
		}
	
	}
}