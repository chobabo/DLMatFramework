#ifndef BASELAYER_H
#define BASELAYER_H
#include <string>
#include <memory>
#include <vector>
#include <algorithm>
#include "utils/tensor.h"

using namespace std;

class BaseLayer
{
public:        
    virtual Tensor<float> ForwardPropagation(const Tensor<float> &input) = 0;
    virtual Tensor<float> BackwardPropagation() = 0;

    void SetWeights(shared_ptr<Tensor<float>> weights){m_weights = weights;}
    void SetBias(shared_ptr<Tensor<float>> weights){m_bias = weights;}
    string GetName() {return m_name;}

protected:
    // Weights and bias are references, we don't need to store them
    shared_ptr<Tensor<float>> m_weights;
    shared_ptr<Tensor<float>> m_bias;

    // We need to cache the activations and gradients for backprop
    unique_ptr<Tensor<float>> m_activation;
    unique_ptr<Tensor<float>> m_gradients;

    vector<int> m_activationShape;

    string m_name;

    // Reference to layers connected to this current layer    
    shared_ptr<BaseLayer> m_inputLayer = nullptr;
};

#endif // BASELAYER_H