#import "markup-shorthands.typ" as markup-shorthands
#import "markup-shorthands.typ": *

#show "†": math.attach("", tr: sym.ast)
#show math.frac: f => $(#f.num) slash (#f.denom)$

#let markup-eval-scope = dictionary(markup-shorthands)
