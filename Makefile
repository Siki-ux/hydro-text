TEXDIR   = dp-text
PRESDIR  = dp-presentation
MAIN_LUA = fi-lualatex
MAIN_PDF = fi-pdflatex
PRES     = fi
FIGDIR   = $(TEXDIR)/figures

# Set BOOK=1 for printed/book format (twoside binding)
BOOK     ?= 0
ifeq ($(BOOK),1)
  BOOKDEF_PDF = "\def\bookformat{}\input{$(MAIN_PDF).tex}"
  BOOKDEF_LUA = "\def\bookformat{}\input{$(MAIN_LUA).tex}"
else
  BOOKDEF =
endif

# Cross-platform commands
ifeq ($(OS),Windows_NT)
    RM      = del /q
    RMDIR   = rmdir /s /q
    OPENER  = start ""
else
    RM      = rm -f
    RMDIR   = rm -rf
    OPENER  = xdg-open
endif

.PHONY: all lua pdf figures docx clean clean-all open open-pdf cover cover1 pres open-pres help

## Default: build with LuaLaTeX (recommended for local use)
all: figures lua

## Regenerate all PlantUML figures (requires plantuml + java)
figures:
	plantuml -tpdf $(FIGDIR)/*.puml

## Build with LuaLaTeX (better fonts, native UTF-8)
## Use `make lua BOOK=1` for printed/book format
lua:
ifeq ($(BOOK),1)
	cd $(TEXDIR) && lualatex -interaction=nonstopmode -jobname=$(MAIN_LUA) $(BOOKDEF_LUA) && biber $(MAIN_LUA) && lualatex -interaction=nonstopmode -jobname=$(MAIN_LUA) $(BOOKDEF_LUA) && lualatex -interaction=nonstopmode -jobname=$(MAIN_LUA) $(BOOKDEF_LUA)
else
	cd $(TEXDIR) && lualatex -interaction=nonstopmode $(MAIN_LUA).tex && biber $(MAIN_LUA) && lualatex -interaction=nonstopmode $(MAIN_LUA).tex && lualatex -interaction=nonstopmode $(MAIN_LUA).tex
endif

## Build with pdfLaTeX (matches Overleaf compiler setting)
## Use `make pdf BOOK=1` for printed/book format
pdf:
ifeq ($(BOOK),1)
	cd $(TEXDIR) && pdflatex -shell-escape -interaction=nonstopmode -jobname=$(MAIN_PDF) $(BOOKDEF_PDF) && biber $(MAIN_PDF) && pdflatex -shell-escape -interaction=nonstopmode -jobname=$(MAIN_PDF) $(BOOKDEF_PDF) && pdflatex -shell-escape -interaction=nonstopmode -jobname=$(MAIN_PDF) $(BOOKDEF_PDF)
else
	cd $(TEXDIR) && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex && biber $(MAIN_PDF) && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex
endif

## Open the LuaLaTeX PDF
open: $(TEXDIR)/$(MAIN_LUA).pdf
	$(OPENER) $(TEXDIR)/$(MAIN_LUA).pdf

## Open the pdfLaTeX PDF
open-pdf: $(TEXDIR)/$(MAIN_PDF).pdf
	$(OPENER) $(TEXDIR)/$(MAIN_PDF).pdf

## Build the hardcover book cover (separate PDF)
cover:
	cd $(TEXDIR) && pdflatex -shell-escape -interaction=nonstopmode cover.tex

## Build the Czech hardcover book cover (separate PDF)
cover1:
	cd $(TEXDIR) && pdflatex -shell-escape -interaction=nonstopmode cover_1.tex

## Build defense presentation with LuaLaTeX
pres:
	cd $(PRESDIR) && lualatex -interaction=nonstopmode $(PRES).tex && biber $(PRES) && lualatex -interaction=nonstopmode $(PRES).tex && lualatex -interaction=nonstopmode $(PRES).tex

## Open the defense presentation PDF
open-pres: $(PRESDIR)/$(PRES).pdf
	$(OPENER) $(PRESDIR)/$(PRES).pdf

## Remove build artifacts (keep PDFs)
clean:
	cd $(TEXDIR) && $(RM) *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.lof *.log *.lot *.out *.run.xml *.synctex.gz *.toc *.xdv *.idx *.ilg *.ind *.ist 2>nul || true

## Convert thesis to DOCX (requires pandoc)
docx:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/to-docx.ps1 -TexDir $(TEXDIR) -Main $(MAIN_LUA)
else
	@mkdir -p $(TEXDIR)/_pandoc_tmp && \
	  cp $(TEXDIR)/chapters/*.tex $(TEXDIR)/_pandoc_tmp/ && \
	  for f in $(TEXDIR)/_pandoc_tmp/*.tex; do \
	    sed -i '/\\begin{tikzpicture}/,/\\end{tikzpicture}/c\\\\emph{[Figure: see PDF version]}' "$$f"; \
	  done && \
	  sed 's|chapters/|_pandoc_tmp/|g; /\\usetikzlibrary/d; /\\usepackage{tikz}/d' \
	    $(TEXDIR)/$(MAIN_LUA).tex > $(TEXDIR)/_pandoc_main.tex && \
	  cd $(TEXDIR) && pandoc _pandoc_main.tex --bibliography=thesis.bib --citeproc -o $(MAIN_LUA).docx && \
	  rm -rf _pandoc_main.tex _pandoc_tmp
endif

## Remove build artifacts AND PDFs
clean-all: clean
	cd $(TEXDIR) && $(RM) *.pdf 2>nul || true

## Count standard pages (1 page = 1,800 characters, LaTeX commands stripped)
pagecount:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/pagecount.ps1 -Dir $(TEXDIR)/chapters
else
	@total=0; for f in $(TEXDIR)/chapters/*.tex; do \
	  n=$$(sed 's/%.*//; s/\\[a-zA-Z]*{//g; s/\\[a-zA-Z]*//g; s/[{}\\]//g' "$$f" | tr -s '[:space:]' ' ' | wc -c); \
	  p=$$(echo "scale=1; $$n / 1800" | bc); \
	  total=$$((total + n)); \
	  printf "  %-25s %6d chars = %5s pages\n" "$$(basename $$f)" "$$n" "$$p"; \
	done; \
	p=$$(echo "scale=1; $$total / 1800" | bc); \
	printf "\n  TOTAL: %d chars = %s standard pages (target: 50-70)\n" "$$total" "$$p"
endif

help:
	@echo "Targets:"
	@echo "  all        Build figures + PDF with LuaLaTeX (default)"
	@echo "  figures    Regenerate PlantUML figures (PDF)"
	@echo "  lua        Build with LuaLaTeX (local, recommended)"
	@echo "  pdf        Build with pdfLaTeX  (matches Overleaf)"
	@echo "  pres       Build defense presentation (LuaLaTeX)"
	@echo "  open       Open LuaLaTeX PDF in viewer"
	@echo "  open-pdf   Open pdfLaTeX PDF in viewer"
	@echo "  open-pres  Open defense presentation PDF"
	@echo "  pagecount  Count standard pages (1 page = 1800 chars)"
	@echo "  docx       Convert thesis to DOCX (requires pandoc)"
	@echo "  clean      Remove build artifacts (keep PDFs)"
	@echo "  clean-all  Remove build artifacts and PDFs"
