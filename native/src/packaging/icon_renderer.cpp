// Renders the same source icon used by Kyna into desktop packaging formats.
#include <QCoreApplication>
#include <QImageReader>
#include <QImage>
#include <iostream>
int main(int argc,char **argv) {
 QCoreApplication app(argc,argv);
 if(argc!=4)return 2;
 bool valid=false;const auto size=QString::fromLocal8Bit(argv[3]).toInt(&valid);
 if(!valid||size<16||size>1024)return 2;
 QImageReader reader(QString::fromLocal8Bit(argv[1]));reader.setScaledSize(QSize(size,size));
 auto image=reader.read();
 if(image.isNull()){std::cerr<<reader.errorString().toStdString()<<'\n';return 1;}
 return image.save(QString::fromLocal8Bit(argv[2]))?0:1;
}
