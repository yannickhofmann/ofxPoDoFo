#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
//	ofSetLogLevel(OF_LOG_VERBOSE);
	doc_.load("ofBook.pdf");
}

//--------------------------------------------------------------
void ofApp::update(){

}

//--------------------------------------------------------------
void ofApp::draw(){
	ofBackground(255);
	doc_.drawPage(page_);
	ofDrawBitmapStringHighlight("Page " + ofToString(page_+1) + " / " + ofToString(doc_.pageCount()), 15, 20);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
	if(key == OF_KEY_LEFT) {
		page_ = std::max(0, page_-1);
	} else if(key == OF_KEY_RIGHT) {
		page_ = std::min<int>(doc_.pageCount() > 0 ? doc_.pageCount()-1 : 0, page_+1);
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
