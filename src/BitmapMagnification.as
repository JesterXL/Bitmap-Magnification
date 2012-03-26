package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class BitmapMagnification extends Sprite
	{
		
		private static const MAGNIFY_WIDTH:Number 	= 160;
		private static const MAGNIFY_HEIGHT:Number 	= 120;
		
		private var nc:NetConnection;
		private var ns:NetStream;
		private var video:Video;
		private var url:String 						= "video.f4v";
		private var ticker:Sprite;
		private var initialSize:Boolean 			= false;
		private var dragging:Boolean 				= false;
		private var magnification:Number 			= 2;
		
		private var originalBitmapData:BitmapData;
		private var videoHolder:Sprite;
		private var bitmapHolder:Sprite;
		private var magnifiedBitmap:Bitmap;
		private var magnifiedBitmapData:BitmapData;
		private var magnifyMask:Shape;
		
		public function BitmapMagnification()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(event:Event):void
		{
			stage.align 		= StageAlign.TOP_LEFT;
			stage.scaleMode 	= StageScaleMode.NO_SCALE;
			
			redrawBackground();
			
			videoHolder = new Sprite();
			addChild(videoHolder);
			
			video = new Video();
			videoHolder.addChild(video);
			
			bitmapHolder = new Sprite();
			addChild(bitmapHolder);
			var g:Graphics = bitmapHolder.graphics;
			g.beginFill(0x333333, .6);
			g.moveTo(-10, 10);
			g.drawRoundRect(-10, -10, MAGNIFY_WIDTH + 20, MAGNIFY_HEIGHT + 20, 6, 6);
			g.endFill();
			bitmapHolder.mouseChildren = bitmapHolder.tabChildren = false;
			bitmapHolder.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			bitmapHolder.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			magnifiedBitmap = new Bitmap();
			bitmapHolder.addChild(magnifiedBitmap);
			
			magnifyMask = new Shape();
			bitmapHolder.addChild(magnifyMask);
			g = magnifyMask.graphics;
			g.beginFill(0x00FF00, .5);
			g.drawRect(0, 0, MAGNIFY_WIDTH, MAGNIFY_HEIGHT);
			g.endFill();
			
			magnifiedBitmap.mask = magnifyMask;
			
			
			nc = new NetConnection();
			nc.connect(null);
			
			ns = new NetStream(nc);
			ns.client = {};
			ns.play(url);
			
			video.attachNetStream(ns);
			
			ticker = new Sprite();
			ticker.addEventListener(Event.ENTER_FRAME, onTick);
			
			stage.addEventListener(Event.RESIZE, onResize);
		}
		
		private function redrawBackground():void
		{
			if(stage == null)
				return;
			
			graphics.clear();
			graphics.beginFill(0xEEEEEE);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		private function onResize(event:Event=null):void
		{
			redrawBackground();
			
			if(video.videoWidth > 0 && video.videoHeight > 0)
			{
				// NOTE: this is what VideoSurface in Strobe/OSMF does in terms of centering
				// the video object itself while mainintaing aspect ratio as the browser resizes.
				
				var aspectRatio:Number = video.videoWidth / video.videoHeight;
				var targetWidth:Number;
				var targetHeight:Number;
				
				targetWidth 			= stage.stageWidth;
				targetHeight 			= stage.stageWidth / aspectRatio;
				
				if(targetHeight > stage.stageHeight)
				{
					targetHeight 		= stage.stageHeight;
					targetWidth 		= targetHeight * aspectRatio;
				}
				
				video.x 				= (stage.stageWidth / 2) - (targetWidth / 2);
				video.y 				= (stage.stageHeight / 2) - (targetHeight / 2);
				video.width 			= targetWidth;
				video.height			= targetHeight;
			}
			
			if(dragging == false)
			{
				bitmapHolder.x = video.x;
				bitmapHolder.y = video.y;
			}
		}
		
		private function onTick(event:Event):void
		{
			if(video)
			{
				var t:SoundTransform 	= ns.soundTransform;
				t.volume 				= 0;
				ns.soundTransform 		= t;
			}
			
			if(video.videoWidth > 0 && video.videoHeight > 0)
			{
				if(initialSize == false)
				{
					initialSize = true;
					onResize();
					
					originalBitmapData 			= new BitmapData(video.videoWidth, video.videoWidth);
					magnifiedBitmapData 		= new BitmapData(MAGNIFY_WIDTH, MAGNIFY_HEIGHT);
					magnifiedBitmap.bitmapData 	= magnifiedBitmapData;
				}
				redrawBitmaps();
			}
		}
		
		private function redrawBitmaps():void
		{
			originalBitmapData.draw(video, video.transform.matrix);
			
			var point:Point = new Point(bitmapHolder.x, bitmapHolder.y);
			point = localToGlobal(point);
			point = videoHolder.globalToLocal(point);
			var xPos:Number = point.x - video.x;
			var yPos:Number = point.y - video.y;
			var zoomArea:Rectangle = new Rectangle(xPos, yPos, MAGNIFY_WIDTH, MAGNIFY_HEIGHT);
			magnifiedBitmapData.copyPixels(originalBitmapData, zoomArea, new Point(0, 0));
			
			magnifiedBitmap.width = MAGNIFY_WIDTH * magnification;
			magnifiedBitmap.height = MAGNIFY_HEIGHT * magnification;
			//magnifiedBitmap.x = (BITMAP_WIDTH - bitmap.width) * (xPos / (videoSurface.videoWidth - BITMAP_WIDTH));
			//magnifiedBitmap.y = (BITMAP_HEIGHT - bitmap.height) * (yPos / (videoSurface.videoHeight - BITMAP_HEIGHT));
			
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			if(dragging == false)
			{
				dragging = true;
				var bounds:Rectangle = new Rectangle(video.x, video.y, video.width - MAGNIFY_WIDTH, video.height - MAGNIFY_HEIGHT);
				bitmapHolder.startDrag(false, bounds);
				addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			event.updateAfterEvent();
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if(dragging)
			{
				dragging = false;
				bitmapHolder.stopDrag();
				removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
		}
	}
}