#pragma once

#include "podofo.h"
#include "ofPath.h"
#include "ofGraphics.h"
#include "ofTrueTypeFont.h"
#include <string>

namespace ofx { namespace podofo {
class Page {
public:
	struct TextEntry {
		std::string text;
		glm::vec2 pos;
		ofRectangle bbox;
		bool has_bbox = false;
		float size = 14.f;
	};

	void addPath(const ofPath &path) {
		path_.push_back(path);
	}
	void addText(const TextEntry &text) {
		text_.push_back(text);
	}
	void draw(const ofTrueTypeFont *font, float baseFontSize) const {
		for(auto &&p : path_) {
			p.draw();
		}
		ofPushStyle();
		ofSetColor(0);
		for(auto &&t : text_) {
			if(font && font->isLoaded()) {
				float scale = t.size > 0 ? t.size / baseFontSize : 1.0f;
				ofPushMatrix();
				ofTranslate(t.pos);
				ofScale(scale, scale);
				font->drawStringAsShapes(t.text, 0, 0);
				ofPopMatrix();
			} else {
				// Fallback if font failed to load.
				ofDrawBitmapString(t.text, t.pos);
			}
		}
		ofPopStyle();
	}
	const std::vector<TextEntry>& getTextEntries() const {
		return text_;
	}
private:
	std::vector<ofPath> path_;
	std::vector<TextEntry> text_;
};
class Document {
public:
	Document();
	// Returns true on successful load, false otherwise.
	bool load(const std::string &filepath);
	// Concatenate extracted text from all pages (newline separated).
	std::string getText() const;
	void draw() const;
	void drawPage(std::size_t index) const;
	std::size_t pageCount() const { return page_.size(); }
private:
	std::vector<Page> page_;
	ofTrueTypeFont font_;
	bool fontLoaded_ = false;
	float baseFontSize_ = 12.f;
};
}}

using ofxPoDoFo = ofx::podofo::Document;
