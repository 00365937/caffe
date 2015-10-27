#ifndef __OPENCL_VERSION__
#include "header.cl"
#endif

__kernel void TEMPLATE(im2col,Dtype)(const int_tp n, __global const Dtype* data_im, const int_tp data_im_off,
    const int_tp height, const int_tp width, const int_tp kernel_h, const int_tp kernel_w,
    const int_tp pad_h, const int_tp pad_w,
    const int_tp stride_h, const int_tp stride_w,
    const int_tp height_col, const int_tp width_col,
    __global Dtype* data_col, const int_tp data_col_off) {

  for (int_tp index = get_global_id(0); index < n; index += get_global_size(0)) {
    int_tp w_out = index % width_col;
    int_tp h_index = index / width_col;
    int_tp h_out = h_index % height_col;
    int_tp channel_in = h_index / height_col;
    int_tp channel_out = channel_in * kernel_h * kernel_w;
    int_tp h_in = h_out * stride_h - pad_h;
    int_tp w_in = w_out * stride_w - pad_w;
    __global Dtype* data_col_ptr = data_col + data_col_off;
    data_col_ptr += (channel_out * height_col + h_out) * width_col + w_out;
    __global const Dtype* data_im_ptr = data_im + data_im_off;
    data_im_ptr += (channel_in * height + h_in) * width + w_in;
    for (int_tp i = 0; i < kernel_h; ++i) {
      for (int_tp j = 0; j < kernel_w; ++j) {
        int_tp h = h_in + i;
        int_tp w = w_in + j;
        *data_col_ptr = (h >= 0 && w >= 0 && h < height && w < width) ?
            data_im_ptr[i * width + j] : 0;
        data_col_ptr += height_col * width_col;
      }
    }
  }
}

__kernel void TEMPLATE(col2im,Dtype)(const int_tp n, __global const Dtype* data_col, const int_tp data_col_off,
    const int_tp height, const int_tp width, const int_tp channels,
    const int_tp patch_h, const int_tp patch_w,
    const int_tp pad_h, const int_tp pad_w,
    const int_tp stride_h, const int_tp stride_w,
    const int_tp height_col, const int_tp width_col,
    __global Dtype* data_im, const int_tp data_im_off) {
  for (int_tp index = get_global_id(0); index < n; index += get_global_size(0)) {
    Dtype val = 0;
    int_tp w = index % width + pad_w;
    int_tp h = (index / width) % height + pad_h;
    int_tp c = index / (width * height);
    // compute the start and end of the output
    int_tp w_col_start = (w < patch_w) ? 0 : (w - patch_w) / stride_w + 1;
    int_tp w_col_end = min(w / stride_w + 1, width_col);
    int_tp h_col_start = (h < patch_h) ? 0 : (h - patch_h) / stride_h + 1;
    int_tp h_col_end = min(h / stride_h + 1, height_col);
    int_tp offset = data_col_off +
        (c * patch_h * patch_w + h * patch_w + w) * height_col * width_col;
    int_tp coeff_h_col = (1 - stride_h * patch_w * height_col) * width_col;
    int_tp coeff_w_col = (1 - stride_w * height_col * width_col);
    for (int_tp h_col = h_col_start; h_col < h_col_end; ++h_col) {
      for (int_tp w_col = w_col_start; w_col < w_col_end; ++w_col) {
        val += data_col[offset + h_col * coeff_h_col + w_col * coeff_w_col];
      }
    }
    data_im[index + data_im_off] = val;
  }
}
