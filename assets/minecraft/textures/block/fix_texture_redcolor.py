# Мне надо на png текстуре всем пикселям с 254 и 253 прозрачностю делать 255 прозрачность.

from PIL import Image
print('start')
name = input('File name (for test.png enter test): ')
imported_image = Image.open(name+'.png')
w,h = imported_image.size
print(w,h)
imported_image_loaded = imported_image.load()
output_image = Image.new(mode='RGBA',size=(w,h))

for x in range(w):
    for y in range(h):
        pixel = imported_image_loaded[x, y]
        if (pixel[0] == 250) or (pixel[0] == 251) or (pixel[0] == 252) or (pixel[0] == 253) or (pixel[0] == 254):
            #print(' bad',x,y,imported_image_loaded[x, y])
            output_image.putpixel( (x,y), (249,pixel[1],pixel[2],255))
            print('replaced badpixel at ',x,y)
        else:
            #print('good',x,y,imported_image_loaded[x, y])
            output_image.putpixel( (x,y), pixel)

output_image.save(name+'.png')
input('end')
