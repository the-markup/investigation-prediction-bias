#!/bin/bash
for filename in ./datasheets/*-for-pdf.html; do
    for ((i=0; i<=3; i++)); do
        pandoc "$filename" -t latex -o "datasheets/pdfs/$(basename "$filename" -for-pdf.html).pdf"
    done
done


# rm ./datasheets/*-for-pdf.html

rm ./datasheets/*-for-pdf.html
mv ./datasheets/*.html ./datasheets/html/