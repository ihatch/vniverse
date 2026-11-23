//
//  VNInfoView.m
//  Vniverse
//
//  The contents of the Info popup, drawn natively (no web view), so it appears
//  instantly and sizes itself exactly.
//

#import "VNInfoView.h"
#import <CoreText/CoreText.h>


////////////////////////////////////////////////////////////////////////////////
// TEXT
//
// Edit the Info text here. Simple tags:
//   <i>…</i>    italic
//   <h>…</h>    pink highlight (mode names)
//   <n>…</n>    purple (bio names)
//   <a URL>…</a> link, opened in Safari
// Each string in an array is one paragraph.
////////////////////////////////////////////////////////////////////////////////

static NSString * const kTitle   = @"Vniverse";
static NSString * const kVersion = @"v2.1; Nov 2026";
static NSString * const kAuthors = @"Stephanie Strickland and Ian Hatcher";

static NSArray<NSString *> *DescriptionParagraphs(void) {
    return @[
        @"<i>Vniverse</i> is a poetry instrument you can play.",
        @"In <h>DRAW</h> mode, touch and drag to create your own constellations.",
        @"In <h>CONSTELLATIONS</h> mode, explore the ten constellations appearing in the coordinate print book of poems, <i>V : WaveTercets / Losing L’una</i> (SpringGun Press, 2014).",
        @"<h>WAVETERCETS</h> mode plays the entire poem for you, starting at the beginning. Or, by touching any star, you may begin anywhere you like.",
        @"<h>ORACLE</h> mode allows you to pose seven questions to the sky.",
        @"The <h>CLEAR</h> button clears the sky.",
    ];
}

static NSArray<NSString *> *AboutParagraphs(void) {
    return @[
        @"Stephanie Strickland’s <i>V</i> first appeared in print from Penguin, 2002, as an invertible book with two beginnings: <i>V : WaveSon.nets / Losing L’una</i>, winner of the Poetry Society’s Di Castagnola Award. Online it has two additional parts: <i>V : Vniverse</i> (in collaboration with Cynthia Lawson Jaramillo) and <i>Errand Upon Which We Came</i> (in collaboration with M.D. Coverley). It appears in the <i>Electronic Literature Collection 2</i> (2011).",
        @"In 2014, <i>V</i> appeared in a new print edition from SpringGun Press with a new title, <a https://www.stephaniestrickland.com/tercets><i>V : WaveTercets / Losing L’una</i></a>, a new rendering, and this app, created in collaboration with Ian Hatcher.",
    ];
}

static NSArray<NSString *> *BioParagraphs(void) {
    return @[
        @"<n>Stephanie Strickland</n> has published 8 books of poetry, most recently <i>Dragon Logic</i> and <i>V: WaveTercets / Losing L’una</i>, and 11 works of electronic literature. Recent digital poems include <i>House of Trust</i> with Ian Hatcher and <i>Hours of the Night</i> with M.D. Coverley. <i>How the Universe Is Made: Poems New &amp; Selected</i> was published by Ahsahta in 2019. <a https://stephaniestrickland.com>stephaniestrickland.com</a>",
        @"<n>Ian Hatcher</n> is the author of <i>Prosthesis</i> (Poor Claudia, 2016). His code-inflected live performances have been presented widely in North America and Europe. A second poetry app, <i>Abra</i>, created with Amaranth Borsuk and Kate Durbin and published in conjunction with a print artists' book, is available from the App Store. <a https://ianhatcher.net>ianhatcher.net</a>",
    ];
}


////////////////////////////////////////////////////////////////////////////////
// STYLE
////////////////////////////////////////////////////////////////////////////////

static UIColor *RGB(int hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xff) / 255.0 green:((hex >> 8) & 0xff) / 255.0 blue:(hex & 0xff) / 255.0 alpha:1];
}

static UIColor *TextColor(void)      { return RGB(0xf6f6f6); }
static UIColor *HighlightColor(void) { return RGB(0xddaadd); }
static UIColor *NameColor(void)      { return RGB(0xb676c4); }
static UIColor *LinkColor(void)      { return RGB(0x97bce0); }
static UIColor *UnderlineColor(void) { return RGB(0x7a9baf); }
static UIColor *DividerColor(void)   { return [UIColor colorWithRed:102/255.0 green:137/255.0 blue:153/255.0 alpha:0.65]; }
static UIColor *LogoBorderColor(void){ return [UIColor colorWithRed:87/255.0 green:128/255.0 blue:148/255.0 alpha:0.65]; }

static UIFont *Regular(CGFloat size) {
    return [UIFont fontWithName:@"EuphemiaUCAS" size:size] ?: [UIFont systemFontOfSize:size];
}
static UIFont *Italic(CGFloat size) {
    return [UIFont fontWithName:@"EuphemiaUCAS-Italic" size:size] ?: [UIFont italicSystemFontOfSize:size];
}

static NSString * const VNLinkAttribute = @"VNLink";
static const CGFloat kUnderlineDrop = 4.1;   // underline sits this far below the baseline
static const CGFloat kFadeHeight = 26;       // single column: text fades out over this band


// Word spaces as on the old web page: each space is the font's full space
// width less 0.1em. (Text layout here sets Euphemia's upright space much
// narrower than its italic one, about 0.3em against 0.5em, which made the
// upright text look cramped; the web view used 0.5em for both.)
static CGFloat SpaceKern(UIFont *font) {
    static NSMutableDictionary<NSString *, NSNumber *> *cache;
    if (!cache) cache = [NSMutableDictionary dictionary];
    NSString *key = [NSString stringWithFormat:@"%@-%g", font.fontName, font.pointSize];
    NSNumber *known = cache[key];
    if (known) return known.doubleValue;

    CTFontRef ct = (__bridge CTFontRef)font;
    UniChar space = ' ';
    CGGlyph glyph = 0;
    CGSize advance = CGSizeZero;
    if (CTFontGetGlyphsForCharacters(ct, &space, &glyph, 1)) {
        CTFontGetAdvancesForGlyphs(ct, kCTFontOrientationHorizontal, &glyph, &advance, 1);
    }
    CGFloat (^width)(NSString *) = ^CGFloat(NSString *text) {
        NSAttributedString *a = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName: font }];
        CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)a);
        CGFloat w = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
        CFRelease(line);
        return w;
    };
    CGFloat laidOut = width(@"x x") - width(@"xx");
    CGFloat kern = (advance.width > 0 ? advance.width : laidOut) - 0.1 * font.pointSize - laidOut;
    cache[key] = @(kern);
    return kern;
}

static void NarrowSpaces(NSMutableAttributedString *text) {
    NSString *plain = text.string;
    for (NSUInteger i = 0; i < plain.length; i++) {
        unichar c = [plain characterAtIndex:i];
        if (c != ' ' && c != 0x00a0) continue;
        UIFont *font = [text attribute:NSFontAttributeName atIndex:i effectiveRange:NULL];
        if (font) [text addAttribute:NSKernAttributeName value:@(SpaceKern(font)) range:NSMakeRange(i, 1)];
    }
}


// Builds styled text from the simple tags above. Paragraphs are separated by
// line breaks; each gets the line height and the space after it (none after
// the last).
static NSAttributedString *StyledText(NSArray<NSString *> *paragraphs, CGFloat size, CGFloat lineHeight, CGFloat spacingAfter) {
    NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];

    for (NSUInteger p = 0; p < paragraphs.count; p++) {
        NSString *source = [paragraphs[p] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        NSScanner *scanner = [NSScanner scannerWithString:source];
        scanner.charactersToBeSkipped = nil;
        BOOL italic = NO, highlight = NO, name = NO;
        NSString *link = nil;

        while (!scanner.isAtEnd) {
            NSString *text = nil;
            if ([scanner scanUpToString:@"<" intoString:&text] && text.length) {
                UIColor *color = link ? LinkColor() : name ? NameColor() : highlight ? HighlightColor() : TextColor();
                // Keep a link on one line, as before.
                if (link) text = [text stringByReplacingOccurrencesOfString:@" " withString:@" "];
                NSMutableDictionary *attrs = [@{ NSFontAttributeName: italic ? Italic(size) : Regular(size),
                                                 NSForegroundColorAttributeName: color } mutableCopy];
                if (link) attrs[VNLinkAttribute] = [NSURL URLWithString:link];
                [out appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:attrs]];
            }
            if (scanner.isAtEnd) break;
            NSString *tag = nil;
            [scanner scanString:@"<" intoString:NULL];
            [scanner scanUpToString:@">" intoString:&tag];
            [scanner scanString:@">" intoString:NULL];
            if ([tag isEqualToString:@"i"])        italic = YES;
            else if ([tag isEqualToString:@"/i"])  italic = NO;
            else if ([tag isEqualToString:@"h"])   highlight = YES;
            else if ([tag isEqualToString:@"/h"])  highlight = NO;
            else if ([tag isEqualToString:@"n"])   name = YES;
            else if ([tag isEqualToString:@"/n"])  name = NO;
            else if ([tag hasPrefix:@"a "])        link = [[tag substringFromIndex:2] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            else if ([tag isEqualToString:@"/a"])  link = nil;
        }

        // Paragraph style for this paragraph (and the line break after it).
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.minimumLineHeight = lineHeight;
        style.maximumLineHeight = lineHeight;
        style.paragraphSpacing = (p + 1 < paragraphs.count) ? spacingAfter : 0;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        if (p + 1 < paragraphs.count) [out appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        NSRange range = NSMakeRange(0, out.length);
        [out enumerateAttribute:NSParagraphStyleAttributeName inRange:range options:0 usingBlock:^(id value, NSRange r, BOOL *stop) {
            if (!value) [out addAttribute:NSParagraphStyleAttributeName value:style range:r];
        }];
    }

    // Centre the glyphs in each line (TextKit puts extra line height above
    // them), and narrow the word spaces.
    [out enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, out.length) options:0 usingBlock:^(UIFont *font, NSRange r, BOOL *stop) {
        if (font) [out addAttribute:NSBaselineOffsetAttributeName value:@((lineHeight - font.lineHeight) / 2) range:r];
    }];
    NarrowSpaces(out);
    return out;
}


////////////////////////////////////////////////////////////////////////////////
// TEXT BLOCK: draws styled text with TextKit, with lowered, fine underlines
// under links, and opens a link when tapped.
////////////////////////////////////////////////////////////////////////////////

@interface VNTextBlock : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, copy) NSAttributedString *text;
- (CGFloat) heightForWidth:(CGFloat)width;
- (CGFloat) firstBaseline;
@end

@implementation VNTextBlock {
    NSTextStorage *storage;
    NSLayoutManager *layout;
    NSTextContainer *container;
}

- (instancetype) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        storage = [[NSTextStorage alloc] init];
        layout = [[NSLayoutManager alloc] init];
        container = [[NSTextContainer alloc] initWithSize:CGSizeMake(frame.size.width, CGFLOAT_MAX)];
        container.lineFragmentPadding = 0;
        [layout addTextContainer:container];
        [storage addLayoutManager:layout];
        self.opaque = NO;
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void) setText:(NSAttributedString *)text {
    _text = [text copy];
    [storage setAttributedString:_text];
    self.accessibilityLabel = _text.string;

    // VoiceOver: each link is offered as an action.
    NSMutableArray *actions = [NSMutableArray array];
    NSAttributedString *t = _text;
    [t enumerateAttribute:VNLinkAttribute inRange:NSMakeRange(0, _text.length) options:0 usingBlock:^(NSURL *url, NSRange r, BOOL *stop) {
        if (!url) return;
        NSString *label = [NSString stringWithFormat:@"Open %@", [[t.string substringWithRange:r] stringByReplacingOccurrencesOfString:@" " withString:@" "]];
        [actions addObject:[[UIAccessibilityCustomAction alloc] initWithName:label actionHandler:^BOOL(UIAccessibilityCustomAction *action) {
            [self openURL:url];
            return YES;
        }]];
    }];
    self.accessibilityCustomActions = actions;
    [self setNeedsDisplay];
}

- (CGFloat) heightForWidth:(CGFloat)width {
    container.size = CGSizeMake(width, CGFLOAT_MAX);
    [layout ensureLayoutForTextContainer:container];
    return ceil([layout usedRectForTextContainer:container].size.height);
}

// Distance from the top of the block to the first line's baseline.
- (CGFloat) firstBaseline {
    if (storage.length == 0) return 0;
    [layout ensureLayoutForTextContainer:container];
    CGRect line = [layout lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
    CGFloat offset = [[storage attribute:NSBaselineOffsetAttributeName atIndex:0 effectiveRange:NULL] doubleValue];
    return line.origin.y + [layout locationForGlyphAtIndex:0].y - offset;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    if (container.size.width != self.bounds.size.width) {
        container.size = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
        [self setNeedsDisplay];
    }
}

- (void) drawRect:(CGRect)rect {
    NSLayoutManager *layout = self->layout;
    NSTextStorage *storage = self->storage;
    NSTextContainer *container = self->container;
    NSRange glyphs = [layout glyphRangeForTextContainer:container];
    [layout drawGlyphsForGlyphRange:glyphs atPoint:CGPointZero];

    // Link underlines: 1pt, a little below the baseline, line by line.
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [UnderlineColor() setFill];
    [storage enumerateAttribute:VNLinkAttribute inRange:NSMakeRange(0, storage.length) options:0 usingBlock:^(id url, NSRange chars, BOOL *stop) {
        if (!url) return;
        NSRange linkGlyphs = [layout glyphRangeForCharacterRange:chars actualCharacterRange:NULL];
        [layout enumerateLineFragmentsForGlyphRange:linkGlyphs usingBlock:^(CGRect lineRect, CGRect usedRect, NSTextContainer *tc, NSRange lineGlyphs, BOOL *stopLine) {
            NSRange part = NSIntersectionRange(lineGlyphs, linkGlyphs);
            if (part.length == 0) return;
            CGRect box = [layout boundingRectForGlyphRange:part inTextContainer:container];
            NSUInteger ch = [layout characterIndexForGlyphAtIndex:part.location];
            CGFloat offset = [[storage attribute:NSBaselineOffsetAttributeName atIndex:ch effectiveRange:NULL] doubleValue];
            CGFloat baseline = lineRect.origin.y + [layout locationForGlyphAtIndex:part.location].y - offset;
            CGContextFillRect(ctx, CGRectMake(box.origin.x, baseline + kUnderlineDrop, box.size.width, 1));
        }];
    }];
}

- (NSURL *) linkAtPoint:(CGPoint)point {
    if (storage.length == 0) return nil;
    CGFloat fraction = 0;
    NSUInteger glyph = [layout glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:&fraction];
    CGRect box = CGRectInset([layout boundingRectForGlyphRange:NSMakeRange(glyph, 1) inTextContainer:container], -4, -6);
    if (!CGRectContainsPoint(box, point)) return nil;
    NSUInteger ch = [layout characterIndexForGlyphAtIndex:glyph];
    return ch < storage.length ? [storage attribute:VNLinkAttribute atIndex:ch effectiveRange:NULL] : nil;
}

// UIKit also asks this view about its superviews' gestures (the scroll
// view's pan) when the touch starts here, so only judge our own link tap.
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if (gesture.view != self) return [super gestureRecognizerShouldBegin:gesture];
    return [self linkAtPoint:[gesture locationInView:self]] != nil;
}

- (void) tapped:(UITapGestureRecognizer *)tap {
    NSURL *url = [self linkAtPoint:[tap locationInView:self]];
    if (url) [self openURL:url];
}

- (void) openURL:(NSURL *)url {
    [self.window.windowScene openURL:url options:nil completionHandler:nil];
}

@end


////////////////////////////////////////////////////////////////////////////////
// INFO VIEW
////////////////////////////////////////////////////////////////////////////////

@interface VNInfoView () <UIScrollViewDelegate>
@end

@implementation VNInfoView {
    BOOL single;
    UIScrollView *scroll;
    VNTextBlock *title, *authors, *description, *about, *bios;
    UIView *divider1, *divider2, *divider3;
    UIView *logo;          // bordered frame around the image
    UIImageView *logoImage;
    CAGradientLayer *fadeMask;
}

- (instancetype) initWithSingleColumn:(BOOL)singleColumn {
    if ((self = [super initWithFrame:CGRectZero])) {
        single = singleColumn;
        self.backgroundColor = UIColor.clearColor;

        scroll = [[UIScrollView alloc] init];
        scroll.delegate = self;
        scroll.bounces = NO;
        scroll.showsHorizontalScrollIndicator = NO;
        scroll.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;   // the popup is already inside the safe area
        [self addSubview:scroll];

        // Sizes: the single column uses slightly smaller type, closer to the tercets.
        CGFloat bodySize = single ? 13 : 14, notesSize = 13;
        CGFloat bodyLine = single ? 18 : 19, notesLine = single ? 18 : 19;
        CGFloat titleSize = single ? 27 : 30;

        // Title, with the small version label on the same baseline.
        UIFont *titleFont = Italic(titleSize);
        CGFloat titleLine = single ? round(titleSize * 1.1 * 10) / 10 : ceil(titleFont.lineHeight);
        NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:kTitle attributes:@{
            NSFontAttributeName: titleFont, NSForegroundColorAttributeName: TextColor() }];
        [t appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{
            NSFontAttributeName: Regular(titleSize) }]];
        [t appendAttributedString:[[NSAttributedString alloc] initWithString:kVersion attributes:@{
            NSFontAttributeName: Regular(titleSize * 0.3), NSForegroundColorAttributeName: TextColor() }]];
        NSMutableParagraphStyle *ts = [[NSMutableParagraphStyle alloc] init];
        ts.minimumLineHeight = ts.maximumLineHeight = titleLine;
        [t addAttribute:NSParagraphStyleAttributeName value:ts range:NSMakeRange(0, t.length)];
        [t addAttribute:NSBaselineOffsetAttributeName value:@((titleLine - titleFont.lineHeight) / 2) range:NSMakeRange(0, t.length)];
        NarrowSpaces(t);
        title = [self block:t];

        authors = [self block:StyledText(@[kAuthors], bodySize, single ? 16 : ceil(Regular(bodySize).lineHeight), 0)];
        description = [self block:StyledText(DescriptionParagraphs(), bodySize, bodyLine, round(bodySize * 0.9 * 10) / 10)];
        about = [self block:StyledText(AboutParagraphs(), notesSize, notesLine, round(notesSize * 0.9 * 10) / 10)];
        bios = [self block:StyledText(BioParagraphs(), notesSize, notesLine, round(notesSize * 0.9 * 10) / 10)];

        divider1 = [self divider];   // single column only: under the authors
        divider2 = [self divider];   // single column only: between the description and the notes
        divider3 = [self divider];   // above the bios

        // SpringGun Press logo (a plain image; its old link no longer works).
        logo = [[UIView alloc] init];
        logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"springgun2.png"]];
        logoImage.contentMode = UIViewContentModeScaleAspectFit;
        logoImage.userInteractionEnabled = NO;
        [logo addSubview:logoImage];
        logo.layer.borderWidth = 1;
        logo.layer.borderColor = LogoBorderColor().CGColor;
        logo.isAccessibilityElement = YES;
        logo.accessibilityLabel = @"SpringGun Press";
        logo.accessibilityTraits = UIAccessibilityTraitImage;
        [scroll addSubview:logo];

        if (single) {
            fadeMask = [CAGradientLayer layer];
            fadeMask.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.blackColor.CGColor,
                                (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
            self.layer.mask = fadeMask;
        } else {
            divider1.hidden = divider2.hidden = YES;
        }
    }
    return self;
}

- (VNTextBlock *) block:(NSAttributedString *)text {
    VNTextBlock *b = [[VNTextBlock alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
    b.text = text;
    [scroll addSubview:b];
    return b;
}

- (UIView *) divider {
    UIView *d = [[UIView alloc] init];
    d.backgroundColor = DividerColor();
    [scroll addSubview:d];
    return d;
}

- (void) place:(VNTextBlock *)b x:(CGFloat)x y:(CGFloat)y width:(CGFloat)w {
    CGFloat h = [b heightForWidth:w];
    b.frame = CGRectMake(x, y, w, h);
    [b setNeedsDisplay];
}

- (void) placeLogoX:(CGFloat)x y:(CGFloat)y height:(CGFloat)h rightAligned:(BOOL)right {
    UIImage *image = logoImage.image;
    CGFloat w = image.size.height > 0 ? h * image.size.width / image.size.height : h * 5;
    // The image fills the inside of the 1pt border, as before.
    logo.frame = CGRectMake(right ? x - (w + 2) : x, y, w + 2, h + 2);
    logoImage.frame = CGRectMake(1, 1, w, h);
}

- (CGFloat) layoutForWidth:(CGFloat)width {
    CGFloat contentHeight;

    if (single) {
        CGFloat side = 24, text = width - 2 * side;
        BOOL narrow = text <= 424;
        CGFloat logoHeight = narrow ? 28 : 38;

        [self placeLogoX:width - side y:22.5 height:logoHeight rightAligned:YES];
        CGFloat beside = MAX(text - logo.frame.size.width - 12, 120);   // title and names keep clear of the logo
        CGFloat nudge = 27 * 3.9 / 30;                                   // pull the italic V's ink back to the margin
        [self place:title x:side - nudge y:19.2 width:beside + nudge];
        [self place:authors x:side y:CGRectGetMaxY(title.frame) + 2 width:beside];

        CGFloat y = MAX(CGRectGetMaxY(authors.frame), CGRectGetMaxY(logo.frame)) + 27;
        divider1.frame = CGRectMake(side, y, text, 1);
        y += 1 + 26;
        [self place:description x:side y:y width:text];
        y = CGRectGetMaxY(description.frame) + 27;
        divider2.frame = CGRectMake(side, y, text, 1);
        y += 1 + 26;
        [self place:about x:side y:y width:text];
        y = CGRectGetMaxY(about.frame) + 27;
        divider3.frame = CGRectMake(side, y, text, 1);
        y += 1 + 26;
        [self place:bios x:side y:y width:text];
        contentHeight = CGRectGetMaxY(bios.frame) + 68;   // room for Close below the text
    } else {
        // Two columns: the description and logo on the left, the notes on the
        // right. The description is moved down so its last line ends level
        // with the end of the notes.
        CGFloat top = 28, left = 38, leftWidth = 310, rightWidth = 470;
        CGFloat rightX = width - 38 - rightWidth;

        [self place:title x:left - 3.9 y:top width:leftWidth + 3.9];
        [self place:authors x:left y:CGRectGetMaxY(title.frame) + 5 width:leftWidth];

        [self place:about x:rightX y:top width:rightWidth];
        CGFloat y = CGRectGetMaxY(about.frame) + 27;
        divider3.frame = CGRectMake(rightX, y, rightWidth, 1);
        [self place:bios x:rightX y:y + 1 + 26 width:rightWidth];
        CGFloat notesBottom = CGRectGetMaxY(bios.frame);

        CGFloat descHeight = [description heightForWidth:leftWidth];
        CGFloat descTop = MAX(CGRectGetMaxY(authors.frame) + 25, notesBottom - descHeight);
        [self place:description x:left y:descTop width:leftWidth];

        [self placeLogoX:left y:CGRectGetMaxY(description.frame) + 36.6 height:38 rightAligned:NO];
        // Close (110 x 40) sits level with the logo; leave room for it.
        CGFloat closeBottom = CGRectGetMidY(logo.frame) + 20;
        contentHeight = ceil(MAX(CGRectGetMaxY(logo.frame), closeBottom)) + 30;
    }

    scroll.contentSize = CGSizeMake(width, contentHeight);
    return contentHeight;
}

- (CGRect) logoFrame {
    return logo.frame;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    scroll.frame = self.bounds;
    scroll.scrollEnabled = scroll.contentSize.height > self.bounds.size.height + 0.5;
    if (fadeMask) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        fadeMask.frame = self.bounds;
        [CATransaction commit];
        scroll.verticalScrollIndicatorInsets = UIEdgeInsetsMake(kFadeHeight, 0, kFadeHeight, 0);
        [self updateFade];
    }
}

// Single column: the bottom fade is always there; the top fade grows in as
// the text is scrolled, so at rest the title sits crisp near the top edge.
- (void) updateFade {
    CGFloat h = self.bounds.size.height;
    if (!fadeMask || h <= 0) return;
    CGFloat top = MIN(MAX(scroll.contentOffset.y, 0), kFadeHeight) / h;
    CGFloat bottom = kFadeHeight / h;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    fadeMask.locations = @[@0, @(top), @(1 - bottom), @1];
    [CATransaction commit];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateFade];
}


@end
