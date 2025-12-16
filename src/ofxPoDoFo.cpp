#include "ofxPoDoFo.h"
#include "ofxPoDoFoParse.h"

using namespace ofx::podofo;
using namespace PoDoFo;
using namespace std;

Document::Document() = default;

bool Document::load(const std::string &filepath) {
	PoDoFo::PdfMemDocument doc;
	try {
		doc.Load(ofToDataPath(filepath));
	} catch(const PoDoFo::PdfError &err) {
		ofLogError("ofxPoDoFo") << "Failed to load PDF " << filepath << ": " << err.what();
		page_.clear();
		return false;
	}

	if(!fontLoaded_) {
		// Try to load a font that supports Latin-1 (for umlauts).
		std::string fontPath = ofToDataPath("verdana.ttf", true);
		if(!ofFile(fontPath).exists()) {
			fontPath = ofToDataPath("fonts/FreeSans.ttf", true);
		}
		if(ofFile(fontPath).exists()) {
			ofTrueTypeFontSettings settings(fontPath, static_cast<int>(baseFontSize_));
			settings.addRanges(ofAlphabet::Latin);
			settings.addRange(ofUnicode::Latin1Supplement);
			settings.contours = true;
			settings.antialiased = true;
			fontLoaded_ = font_.load(settings);
			if(!fontLoaded_) {
				ofLogWarning("ofxPoDoFo") << "Failed to load font at " << fontPath << " - falling back to bitmap text.";
			}
		} else {
			ofLogWarning("ofxPoDoFo") << "No font found (looked for verdana.ttf and fonts/FreeSans.ttf). Falling back to bitmap text.";
		}
	}

	page_.clear();
	auto &pages = doc.GetPages();
	auto count = pages.GetCount();
	page_.resize(count);
	for(unsigned i = 0; i < count; ++i) {
		auto &page = pages.GetPageAt(i);
		PoDoFo::PdfContentStreamReader reader(page);
		parse::Parser::Context context;
		auto rect = page.GetRect();
		float top = rect.GetBottom() + rect.Height;
		context.mat[1][1] = -1;
		context.mat[3][1] = top;
		auto paths = parse::Parser().parse(reader, context);
		for(auto &&path : paths) {
			page_[i].addPath(path);
		}

		// Text: use PoDoFo extraction (position only) and render at a fixed size.
		std::vector<PoDoFo::PdfTextEntry> entries;
		page.ExtractTextTo(entries);
		for(const auto &entry : entries) {
			Page::TextEntry text;
			text.text = entry.Text;
			text.pos = {static_cast<float>(entry.X), static_cast<float>(top - entry.Y)};
			if(entry.BoundingBox.has_value()) {
				auto r = entry.BoundingBox.value();
				text.bbox = ofRectangle(
					static_cast<float>(r.X),
					static_cast<float>(top - (r.Y + r.Height)),
					static_cast<float>(r.Width),
					static_cast<float>(r.Height));
				text.has_bbox = true;
			}
			text.size = baseFontSize_;
			page_[i].addText(text);
		}
	}

	return true;
}

void Document::draw() const {
	for(auto &&p : page_) {
		p.draw(fontLoaded_ ? &font_ : nullptr, baseFontSize_);
	}
}

void Document::drawPage(std::size_t index) const {
	if(index >= page_.size()) {
		return;
	}
	page_[index].draw(fontLoaded_ ? &font_ : nullptr, baseFontSize_);
}

std::string Document::getText() const {
	std::string combined;
	bool first = true;
	for(std::size_t i = 0; i < page_.size(); ++i) {
		const auto &p = page_[i];
		for(const auto &entry : p.getTextEntries()) {
			if(!first) {
				combined.push_back('\n');
			}
			first = false;
			combined += entry.text;
		}
		// Separate pages with an extra newline for readability (but avoid trailing).
		if(i + 1 < page_.size() && !combined.empty()) {
			combined.push_back('\n');
		}
	}
	return combined;
}
