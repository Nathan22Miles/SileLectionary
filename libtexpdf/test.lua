local pdf = require("justenoughlibtexpdf");

pdf.init("test.pdf", 612, 792)

pdf.beginpage()
pdf.endpage()
pdf.finish()