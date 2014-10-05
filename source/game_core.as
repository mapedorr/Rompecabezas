stop();
//Imports
import flash.utils.*;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.display.DisplayObject;
import flash.geom.Point;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.net.*;
import flash.external.ExternalInterface;
import fl.events.ScrollEvent; 
import fl.containers.ScrollPane; 
import fl.controls.ScrollPolicy; 
import fl.controls.DataGrid; 
import fl.data.DataProvider;

//Global
var cronometro;
var minutos:int;
var segundos:int;
var sSegundos:String;
var separador:String;
var informadorTiempo:String;
var pieces:int;
var piecesInOrder:Array;
var originPiecePosition:Point;
var tiempoJuegoMinutos:int;
var tiempoJuegoSegundos:int;
var tiempoJuegoCompleto:int;
var posicionJugador:int;
var iAmNew:Boolean;
var god:XML;
var thePlayers:XMLList;
var playerXMLElement:XML;
var savedId:int;
var savedNombre:String
var savedCodigo:String
var savedCiudad:String
var savedMinutos:int;
var savedSegundos:int;
var savedIntento:int;
var savedTiempoCompleto:int;
var savedPosicion:int;
var obteinedPlayer:XMLList;
var firstPlayerEver:Boolean;
var clickNuevoIntento:Boolean = false;
var originPiecesConfiguration:Point;
var juegoTerminado:Boolean;
var leeParaGuardar:Boolean;
//Functions
function iniciar(){
	iniciarAttr();
	loadXML();
}
function iniciarAttr(){
	cronometro = new Timer(1000);
	leeParaGuardar = false;
	minutos = 0;
	segundos = 0;
	sSegundos = "s";
	separador = ":";
	informadorTiempo = "00:00s";
	pieces = 9;
	piecesInOrder = new Array(pieces);
	for(var i:int=0;i<piecesInOrder.length;i++){
		piecesInOrder[i] = false;
	}
	juegoTerminado = false;
}
function loadXML(){
	var cargador:URLLoader = new URLLoader();
	cargador.dataFormat = URLLoaderDataFormat.TEXT;
	cargador.addEventListener(Event.COMPLETE,loadCompleted);
	cargador.load( new URLRequest( "data.xml?rnd=" + Math.random() ) );
}
function loadCompleted(event:Event):void{
	try{
		firstPlayerEver = false;
		god = new XML(event.target.data);
		thePlayers = god.jugador;
		if(thePlayers.length() < 1){
			firstPlayerEver = true;
		}
		if(leeParaGuardar == true){
			continueSaving();
		}else{
			if(juegoTerminado == true){
				fillRanking();
				juegoTerminado = false;
				gotoAndPlay("termina_juego");
			}else{
				if(clickNuevoIntento == true){
					clickNuevoIntento = false;
					if(validateMe() == true){
						gotoAndPlay("reinicia");
					}
				}else{
					//Se verifica la existencia del usuario
					var iCanPlay:Boolean = validateMe();
					if(iCanPlay == true){
						root.no_mas_juego.alpha = 0;
						gotoAndPlay("boton_inicio");
					}else{
						root.no_mas_juego.alpha = 100;
					}
				}
			}
		}
	}catch(e:TypeError){
		confirm("1. Error: " + e.getStackTrace());
	}
}
function onThousand(event:TimerEvent):void{
	segundos++;
	if(segundos == 60){
		minutos++;
		segundos = 0;
	}
	informadorTiempo = timeAsText(minutos,segundos);
	contenedor_cronometro.contenedor.campoTexto_cronometro.text = informadorTiempo;
}
function continueClick(event:MouseEvent):void{
	if(campoTexto_registro.text != "" && campoTexto_codigo.text != "" && campoTexto_ciudad.text != ""  ){
		savedNombre = campoTexto_registro.text;
		savedCodigo = campoTexto_codigo.text;
		savedCiudad = campoTexto_ciudad.text;
		iniciar();
	}else{
		//Aquí se podría mostrar (reproducir) un mensaje 
		//indicando que se debe ingresar un nombre
	}
}
function validateMe():Boolean{
	var canPlay:Boolean = true;
	iAmNew = true;
	obteinedPlayer = god.jugador.(nombre == savedNombre);
	if(obteinedPlayer.length() == 1){
		iAmNew = false;
		savedId = obteinedPlayer.@id;
		savedNombre = obteinedPlayer.nombre;
		savedCodigo = obteinedPlayer.codigo;
		savedCiudad = obteinedPlayer.ciudad;
		
		savedMinutos = Number(obteinedPlayer.minutos);
		savedSegundos = Number(obteinedPlayer.segundos);
		savedTiempoCompleto = Number(obteinedPlayer.tiempocompleto);
		savedPosicion = Number(obteinedPlayer.posicion);
		savedIntento = Number(obteinedPlayer.intento);
		if(savedIntento >= 3){
			canPlay = false;
		}
	}
	if(iAmNew == true){
		//Se guarda el nombre en caso de ser necesario
		playerXMLElement = <jugador/>;
		var idOfPlayer:Number = 1;
		
		var ids:XMLList = god.jugador.@id;
		if(ids.length() > 0){
			idOfPlayer = ids.length() + 1;
		}
		//Player element definition
		playerXMLElement.@id = idOfPlayer;
		
		playerXMLElement.nombre = savedNombre;
		playerXMLElement.codigo = savedCodigo;
		playerXMLElement.ciudad = savedCiudad;
		
		playerXMLElement.minutos = savedSegundos = 60;
		playerXMLElement.segundos = savedMinutos = 60;
		playerXMLElement.tiempocompleto = savedTiempoCompleto = ((60 * 60) + 60);
		playerXMLElement.posicion = savedPosicion = thePlayers.length() + 1;
		playerXMLElement.intento = savedIntento = 0;
	}
	return canPlay;
}
function startClick(event:MouseEvent):void{
	hidePieces();
	clickNuevoIntento = false;
	gotoAndPlay("inicio_juego");
}
function doChaos():void{
	for(var i:int=1;i<=pieces;i++){
		//Asignar propiedades
		this["ficha"+i].alpha = 100;
		this["ficha"+i].addEventListener(MouseEvent.MOUSE_DOWN,pickupPiece);
		this["ficha"+i].addEventListener(MouseEvent.MOUSE_UP,placePiece);
	}
}
function hidePieces(){
	if(clickNuevoIntento == false){
		originPiecesConfiguration = new Point(this.ficha1.x,this.ficha1.y);
	}
	var usedPositions:Array = new Array(pieces);
	for(var j:int=0;j<usedPositions.length;j++){
		usedPositions[j] = false;
	}
	
	for(var i:int=1;i<=pieces;i++){
		this["ficha"+i].alpha = 0;
		if(clickNuevoIntento == true){
			this["ficha"+i].x = originPiecesConfiguration.x;
			this["ficha"+i].y = originPiecesConfiguration.y;
		}
		
		var fichaUbicada:Boolean = false;
		while(fichaUbicada == false){
			var randomPos:int = 1 + (Math.random() * ((pieces - 1) + 1) );
			if(usedPositions[randomPos-1] == false){
				usedPositions[randomPos-1] = true;
				fichaUbicada = true;
				this["ficha"+i].x = this["casilla"+randomPos].x;
				this["ficha"+i].y = this["casilla"+randomPos].y;
			}
		}
	}
}
function fillRanking():void{
	if(thePlayers.length() > 0){
		var posx:Number = 0;
		var posy:Number = 0;
		
		while (super_contenedor_ranking.contenedor_ranking.contenedor.numChildren > 0){ 
			super_contenedor_ranking.contenedor_ranking.contenedor.removeChildAt(0); 
		}
		
		for(var i:int=1;i<=thePlayers.length();i++){
			var pkayerIn_i_position:XMLList;
			pkayerIn_i_position = god.jugador.(posicion == i);
			if(pkayerIn_i_position.length() >= 1){
				var dat:DatosJugadorRanking = new  DatosJugadorRanking();
				dat.texto_posicion.text = i.toString();
				dat.texto_nombre.text = ""+pkayerIn_i_position.nombre;
				dat.texto_tiempo.text = timeAsText(""+pkayerIn_i_position.minutos,""+pkayerIn_i_position.segundos);
				
				if(i == 1){
					var fondoPos:FondoPos1 = new FondoPos1();
					dat.contenedor_fondo_pos.addChild(DisplayObject(fondoPos));
				}else{
					var fondoPos2:FondoPos2 = new FondoPos2();
					dat.contenedor_fondo_pos.addChild(DisplayObject(fondoPos2));
				}
				
				dat.x = posx;
				dat.y = posy;
				
				posy += dat.height + 5;
				
				super_contenedor_ranking.contenedor_ranking.contenedor.addChild(dat);
			}
		}
		if(super_contenedor_ranking.contenedor_ranking.height >= super_contenedor_ranking.scroll_pane.height){
			super_contenedor_ranking.scroll_pane.source = super_contenedor_ranking.contenedor_ranking;
			super_contenedor_ranking.scroll_pane.alpha = 9;
			super_contenedor_ranking.scroll_pane.update();
			super_contenedor_ranking.scroll_pane.refreshPane();
		}else{
			super_contenedor_ranking.contenedor_ranking.x = super_contenedor_ranking.scroll_pane.x;
			super_contenedor_ranking.contenedor_ranking.y = super_contenedor_ranking.scroll_pane.y;
			super_contenedor_ranking.scroll_pane.alpha = 0;
		}
	}else{
		super_contenedor_ranking.scroll_pane.alpha = 0;
	}
}
function pickupPiece(event:MouseEvent):void{
	originPiecePosition = new Point(event.target.x,event.target.y);
	setChildIndex(DisplayObject(event.target),numChildren - 1);
	var zoneOfMove:Rectangle = new Rectangle(this.area_tablero.x,this.area_tablero.y,this.area_tablero.width,this.area_tablero.height);
	//event.target.startDrag(false,zoneOfMove);
	event.target.startDrag();
}
function placePiece(event:MouseEvent):void{
	var targetObj:Object = event.target;
	var dropTargetObj:Object = event.target.dropTarget;
	targetObj.stopDrag();
	
	if(dropTargetObj.name.indexOf("casilla") >= 0
	   || dropTargetObj.parent.name.indexOf("ficha") >= 0){
		targetObj.x = dropTargetObj.parent.x;
		targetObj.y = dropTargetObj.parent.y;
		if(dropTargetObj.parent.name.indexOf("ficha") >= 0){
			dropTargetObj.parent.x = originPiecePosition.x;
			dropTargetObj.parent.y = originPiecePosition.y;
		}
		if(finishedGame(targetObj,dropTargetObj)){
			stopGame();
		}
	}else{
		targetObj.x = originPiecePosition.x;
		targetObj.y = originPiecePosition.y;
	}
}
function finishedGame(targetObj,dropTargetObj):Boolean{
	var piecesInOrderNumber:int = 0;
	for(var i:int=0;i<piecesInOrder.length;i++){
		if(this["ficha"+(i+1)].x == this["casilla"+(i+1)].x
		   	&& this["ficha"+(i+1)].y == this["casilla"+(i+1)].y){
			piecesInOrderNumber++;
		}
	}
	if(piecesInOrderNumber == piecesInOrder.length){
		return true;
	}
	return false;
}
function stopGame():void{
	cronometro.stop();
	for(var i:int=1;i<=pieces;i++){
		this["ficha"+i].removeEventListener(MouseEvent.MOUSE_DOWN,pickupPiece);
		this["ficha"+i].removeEventListener(MouseEvent.MOUSE_UP,placePiece);
	}
	
	juegoTerminado = true;
	
	tiempoJuegoMinutos = minutos;
	tiempoJuegoSegundos = segundos;
	tiempoJuegoCompleto = (minutos * 60) + segundos;
	
	savedIntento++;
	
	//¿Se lee el XML para actualizar datos?
	leeParaGuardar = true;
	loadXML();
}
function continueSaving(){
	var tiemposMejorados:Boolean = false;
	
	validateMe();
	
	if(iAmNew){
		if(tiempoJuegoCompleto < savedTiempoCompleto){
			playerXMLElement.minutos = savedMinutos = tiempoJuegoMinutos;
			playerXMLElement.segundos = savedSegundos = tiempoJuegoSegundos;
			playerXMLElement.tiempocompleto = savedTiempoCompleto = tiempoJuegoCompleto;
			
			tiemposMejorados = true;
		}
		if(tiemposMejorados == true && firstPlayerEver == false){
			//Se determina la posición del jugador
			playerXMLElement.posicion = savedPosicion = setMyPosition(Number(playerXMLElement.@id));
		}else if(tiemposMejorados == true && firstPlayerEver == true){
			playerXMLElement.posicion = savedPosicion = 1;
		}
		playerXMLElement.intento = savedIntento;
		god = god.appendChild(playerXMLElement);
	}else{
		if(tiempoJuegoCompleto < savedTiempoCompleto){
			tiemposMejorados = true;
		}
		
		if(tiemposMejorados == true){
			//Se determina la posición del jugador
			obteinedPlayer.posicion = savedPosicion = setMyPosition(Number(obteinedPlayer.@id));
		}else{
			var pkayerIn_i_position:XMLList = god.jugador.(posicion == savedPosicion);
			pkayerIn_i_position.intento = savedIntento;
		}
	}
	
	saveXML();
}
function setMyPosition(myID:Number):int{
	var miPos:int = savedPosicion;
	var desde:int = thePlayers.length();
	//Se compara el tiempo con las posiciones en el XML
	for(var i:int=1;i<=thePlayers.length();i++){
		var pkayerIn_i_position:XMLList = god.jugador.(posicion == i);
		var pkayerIn_i_position_ID:Number = Number(pkayerIn_i_position.@id);
		if(pkayerIn_i_position_ID != myID){
			var pkayerIn_i_position_time:Number = Number(pkayerIn_i_position.tiempocompleto);
			if(tiempoJuegoCompleto < pkayerIn_i_position_time){
				if(iAmNew == false){
					desde = miPos;
				}
				//Soy mejor
				miPos = i;				
				//Todos los jugadores del (i) en adelante tienen que moverse
				moverPosiciones(desde,i);
				break;
			}else if(tiempoJuegoCompleto == pkayerIn_i_position_time){
				//Parejos, pero...quién se registró primero?
				if(myID < pkayerIn_i_position_ID){
					if(iAmNew == false){
						desde = miPos;
					}
					//Soy mejor porque me registré primero
					miPos = i;
					//Todos los jugadores del (i) en adelante tienen que moverse
					moverPosiciones(desde,i);
					break;
				}
			}
		}else{
			if(tiempoJuegoCompleto < savedTiempoCompleto){
				pkayerIn_i_position.minutos = savedMinutos = tiempoJuegoMinutos;
				pkayerIn_i_position.segundos = savedSegundos = tiempoJuegoSegundos;
				pkayerIn_i_position.tiempocompleto = savedTiempoCompleto = tiempoJuegoCompleto;
				pkayerIn_i_position.intento = savedIntento;
				break;
			}
		}
	}
	return miPos;
}
function moverPosiciones(desde:int,hasta:int):void{
	var coconero:XMLList;
	for(var i:int=desde;i>=hasta;i--){
		var pkayerIn_i_position:XMLList;
		pkayerIn_i_position = god.jugador.(posicion == i);
		if(pkayerIn_i_position.length() >= 1){
			if(iAmNew == false
				&& Number(pkayerIn_i_position.@id) == Number(obteinedPlayer.@id)){
				coconero = pkayerIn_i_position;
			}else{
				if(iAmNew == false){
					if((i+1) <= thePlayers.length()){
						pkayerIn_i_position.posicion = (i+1);
					}
				}else{
					pkayerIn_i_position.posicion = (i+1);
				}
			}
		}
	}
	if(iAmNew == false){
		coconero.posicion = hasta;
		coconero.minutos = savedMinutos = tiempoJuegoMinutos;
		coconero.segundos = savedSegundos = tiempoJuegoSegundos;
		coconero.tiempocompleto = savedTiempoCompleto = tiempoJuegoCompleto;
		coconero.intento = savedIntento;
	}
}
function saveXML(){
	var request:URLRequest = new URLRequest("helper.php?rnd="+ Math.random());
	request.data = god;
	request.contentType = "text/xml";
	request.method = URLRequestMethod.POST;
	var loader:URLLoader = new URLLoader();
	loader.addEventListener(Event.COMPLETE,savedXML);
	loader.load(request);
}
function savedXML(event:Event):void{
	try{
		if((""+event.target.data).indexOf("1") >= 0){
			juegoTerminado = true;
			leeParaGuardar = false;
			loadXML();
		}
	}catch(e:TypeError){
		confirm("2. Error: " + e.getStackTrace());
	}
}
function resultsReport():void{
	this.popup_ranking.tiempo_juego.text = timeAsText(""+tiempoJuegoMinutos,""+tiempoJuegoSegundos);
	this.popup_ranking.posicion_tabla.text = savedPosicion;
}
function cerrarPopup(event:MouseEvent):void{
	root.gotoAndPlay("nuevo_intento");
}
function nuevoIntento(event:MouseEvent):void{
	if(savedIntento >= 3){
		this.nuevo_intento.removeEventListener(MouseEvent.CLICK,nuevoIntento);
		this.nuevo_intento.alpha = 0;
		setChildIndex(DisplayObject(root.no_mas_juego),numChildren - 1);
		root.no_mas_juego.alpha = 100;
		root.instruccion_arrastre.alpha=0;
	}else{
		root.clickNuevoIntento = true;
		root.leeParaGuardar = false;
		root.cleanScene();
		root.cronometro.removeEventListener(TimerEvent.TIMER,onThousand);
		root.contenedor_cronometro.gotoAndPlay(1);
		root.no_mas_juego.alpha = 0;
		root.iniciar();
	}
}
function cleanScene(){
	root.removeChild(super_contenedor_ranking);
	for(var i:int=1;i<=pieces;i++){
		root.removeChild(DisplayObject(this["ficha"+i]));
		root.removeChild(DisplayObject(this["casilla"+i]));
	}
}
//Event handlers
boton_continuar.addEventListener(MouseEvent.CLICK,continueClick);