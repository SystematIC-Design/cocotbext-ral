# MIT License

# Copyright (c) 2021 SystematIC Design BV

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

all: clean rtl ral sim waves

venv:
	python3 -m venv venv ; \
	. venv/bin/activate ; \
	pip install --upgrade pip ; \
	pip install wheel setuptools ; \
	pip install --upgrade setuptools ; \
	pip install -r requirements.txt

clean:
	@echo
	@echo "Cleaning"
	@rm -rf tb_coco/sim_build
	@rm -f transcript
	@rm -f tb_coco/transcript
	@rm -f tb_coco/*.wlf

rtl:
	@echo
	@echo "Generating RTL of the register file"
	./util/regtool.py -r ./data/example.hjson

ral:
	@echo
	@echo "Generating RAL model of the register file"
	./util/regtool.py -u ./data/example.hjson

sim:
	@echo
	@echo "Running simulation"
	@cd tb_coco && $(MAKE)

waves:
	@echo
	@echo "Launching waves"
	cd tb_coco && vsim vsim.wlf -do "wave.do"